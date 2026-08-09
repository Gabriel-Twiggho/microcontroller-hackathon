// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 Analog Devices, Inc.
//===-- MYISAISelDAGToDAG.cpp - MYISA DAG->DAG Instruction Selection -----===//
//
// WHAT THIS FILE IS:
//   Implements the instruction selection pass — the transformation from a
//   legalized SelectionDAG (abstract operations on virtual registers) into
//   MachineInstrs (concrete MYISA instructions). This is where abstract DAG
//   nodes like "add" become concrete opcodes like MYISA::ADD_rrr.
//
// WHY IT MUST EXIST:
//   While TableGen patterns (in MYISAInstrInfo.td) handle most instruction
//   selection automatically via SelectCode(), some operations need custom C++
//   logic that cannot be expressed as a TableGen pattern:
//     - Constant materialization (choosing between ADD_rri, LI, or NEG+LI)
//     - CALLSEQ_START/END handling (result type mismatch with TableGen)
//     - Custom node selection (MYISAISD::CALL, CMP, BR_CC)
//     - Complex addressing mode decomposition (SelectAddr)
//     - Peephole optimizations (ADD with negative constant → SUB)
//
// WHAT EACH PART DOES:
//   MYISADAGToDAGISel class:
//     - Inherits from SelectionDAGISel (LLVM's ISel framework)
//     - Includes MYISAGenDAGISel.inc (TableGen-generated pattern matcher)
//     - Overrides Select() to handle custom cases before falling through
//       to SelectCode() for pattern-based matching
//
//   Select() method (the core of this file):
//     Handles these cases before falling through to SelectCode():
//       ISD::Constant — Multi-strategy constant materialization:
//         0–31:      ADD rd, r0, #imm (single instruction, 5-bit immediate)
//         32–65535:  LI rd, #imm (single instruction, 16-bit immediate)
//         -1..-31:   ADD rd, r0, #abs; NEG rd, rd (two instructions)
//         -32..-65535: LI rd, #abs; NEG rd, rd (two instructions)
//         Others:    fall through to ISelLowering (LUI+OR, multi-insn)
//       ISD::ADD — Peephole: add(x, -small_const) → SUB_rri(x, abs)
//       ISD::CALLSEQ_START/END — Manual selection to ADJCALLSTACKDOWN/UP
//       MYISAISD::CALL — Repacks operands for CALL machine instruction
//       MYISAISD::CMP — Selects between CMP_rr and CMP_ri
//       MYISAISD::BR_CC — Maps condition codes to branch opcodes
//
//   SelectAddr() method:
//     Implements the ComplexPattern "addr" from MYISAInstrInfo.td.
//     Decomposes an address expression into (Base, Offset) for memory
//     instructions. Handles three cases:
//       FrameIndex → (FI, 0)
//       reg + const → (reg, const) if const fits in 16 bits
//       reg + reg → (reg, reg) with 0 offset
//       bare reg → (reg, 0)
//
// WHAT COULD BE ADDED:
//   - Peephole optimizations: combine LOAD+SIGN_EXTEND, fuse CMP+Branch pairs
//   - More aggressive constant materialization for large values (LUI sequences)
//   - Post-ISel peephole pass integration (addPreEmitPass)
//   - Custom lowering for multiply-accumulate if hardware adds MAC instruction
//   - Address mode folding for scaled-offset memory accesses
//   - Predicated instruction selection if hardware adds conditional execution
//   - VLIW scheduling considerations if hardware adds instruction bundles
//
//===----------------------------------------------------------------------===//

#include "MYISA.h"
#include "MYISAISelLowering.h"
#include "MYISASubtarget.h"
#include "MYISATargetMachine.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/SelectionDAGISel.h"
#include "llvm/CodeGen/SelectionDAGNodes.h"
#include "llvm/Support/ErrorHandling.h"

using namespace llvm;

#define DEBUG_TYPE "myisa-isel"

namespace {

// MYISADAGToDAGISel — The instruction selection pass for MYISA.
// This is a FunctionPass that runs on each function in the module.
// It transforms the SelectionDAG (after legalization) into MachineInstrs
// by calling Select() on each DAG node in bottom-up order.
class MYISADAGToDAGISel : public SelectionDAGISel {
  const MYISASubtarget *Subtarget;

public:
  static char ID;

  MYISADAGToDAGISel(MYISATargetMachine &TM, CodeGenOpt::Level OL)
      : SelectionDAGISel(ID, TM, OL) {}

  // runOnMachineFunction — Called once per function. Caches the subtarget
  // reference, then delegates to the base class which drives Select().
  bool runOnMachineFunction(MachineFunction &MF) override {
    Subtarget = &MF.getSubtarget<MYISASubtarget>();
    return SelectionDAGISel::runOnMachineFunction(MF);
  }

  // Select — Called for each DAG node. Our override handles custom cases;
  // unhandled nodes fall through to SelectCode() (TableGen patterns).
  void Select(SDNode *N) override;

  // SelectAddr — ComplexPattern implementation for memory address decomposition.
  // Called by the TableGen-generated code when matching the "addr" pattern.
  bool SelectAddr(SDValue Addr, SDValue &Base, SDValue &Offset);

  StringRef getPassName() const override {
    return "MYISA DAG->DAG Pattern Instruction Selection";
  }

// Include the TableGen-generated pattern matching code.
// SelectCode() is defined here — it's a giant switch/case that matches
// DAG patterns to MYISA instructions based on MYISAInstrInfo.td patterns.
#include "MYISAGenDAGISel.inc"
};

char MYISADAGToDAGISel::ID = 0;

} // end anonymous namespace

//===----------------------------------------------------------------------===//
// Select — The main instruction selection dispatch
//
// This is called bottom-up for every node in the SelectionDAG. Nodes that
// have already been selected (isMachineOpcode()) are skipped. Custom cases
// are handled by the switch statement; everything else falls through to
// SelectCode() which applies TableGen patterns.
//===----------------------------------------------------------------------===//

void MYISADAGToDAGISel::Select(SDNode *N) {
  // Already selected by a previous pass or TableGen — skip.
  if (N->isMachineOpcode()) {
    N->setNodeId(-1);
    return;
  }

  switch (N->getOpcode()) {
  default:
    break;  // Fall through to SelectCode() for TableGen pattern matching

  case ISD::Constant: {
    auto *C = cast<ConstantSDNode>(N);
    int64_t Value = C->getSExtValue();

    // Non-negative 16-bit constants are handled by the LI TableGen pattern.
    if (Value >= 0 && Value <= 65535)
      break;

    // Materialise signed negative constants using the architectural zero
    // register.  Small magnitudes fit directly in SUB's five-bit immediate;
    // larger signed-16 magnitudes first use LI and then register SUB.
    if (Value < 0 && Value >= -65535) {
      SDLoc DL(N);
      uint64_t Magnitude = static_cast<uint64_t>(-Value);
      SDNode *Result;

      if (Magnitude <= 31) {
        SDValue Imm =
            CurDAG->getTargetConstant(Magnitude, DL, MVT::i32);
        Result = CurDAG->getMachineNode(MYISA::LI_NEG_ri, DL, MVT::i32,
                                        Imm);
      } else {
        SDValue Imm =
            CurDAG->getTargetConstant(Magnitude, DL, MVT::i32);
        SDNode *Positive =
            CurDAG->getMachineNode(MYISA::LI, DL, MVT::i32, Imm);
        Result = CurDAG->getMachineNode(MYISA::LI_NEG_rr, DL, MVT::i32,
                                        SDValue(Positive, 0));
      }

      ReplaceNode(N, Result);
      return;
    }

    report_fatal_error(
        "MYISA cannot materialise constants outside signed/unsigned 16-bit range");
  }

  case MYISAISD::CMP: {
    SDLoc DL(N);
    SDValue Chain = N->getOperand(0);
    SDValue LHS = N->getOperand(1);
    SDValue RHS = N->getOperand(2);
    unsigned Opcode = MYISA::CMP_rr;
    SmallVector<SDValue, 3> Ops;
    Ops.push_back(LHS);

    if (auto *C = dyn_cast<ConstantSDNode>(RHS)) {
      int64_t Value = C->getSExtValue();
      if (Value >= 0 && Value <= 31) {
        Opcode = MYISA::CMP_ri;
        Ops.push_back(CurDAG->getTargetConstant(Value, DL, MVT::i32));
      } else {
        Ops.push_back(RHS);
      }
    } else {
      Ops.push_back(RHS);
    }
    Ops.push_back(Chain);

    SDNode *Result = CurDAG->getMachineNode(Opcode, DL, MVT::Other, Ops);
    ReplaceNode(N, Result);
    return;
  }

  case MYISAISD::BR_CC: {
    SDLoc DL(N);
    SDValue Chain = N->getOperand(0);
    ISD::CondCode CC = static_cast<ISD::CondCode>(
        cast<ConstantSDNode>(N->getOperand(1))->getZExtValue());
    SDValue Target = N->getOperand(2);
    unsigned Opcode;

    switch (CC) {
    case ISD::SETEQ: Opcode = MYISA::JZ; break;
    case ISD::SETNE: Opcode = MYISA::JNZ; break;
    case ISD::SETLT: Opcode = MYISA::JLT; break;
    case ISD::SETGT: Opcode = MYISA::JGT; break;
    default: report_fatal_error("Unsupported MYISA branch condition");
    }

    SDValue Ops[] = {Target, Chain};
    SDNode *Result = CurDAG->getMachineNode(Opcode, DL, MVT::Other, Ops);
    ReplaceNode(N, Result);
    return;
  }

  case MYISAISD::CALL: {
    SDLoc DL(N);
    SmallVector<SDValue, 12> Ops;

    // Machine CALL order: target, variadic register uses/mask, chain, glue.
    Ops.push_back(N->getOperand(1));
    SDValue Glue;
    for (unsigned I = 2; I < N->getNumOperands(); ++I) {
      if (N->getOperand(I).getValueType() == MVT::Glue)
        Glue = N->getOperand(I);
      else
        Ops.push_back(N->getOperand(I));
    }
    Ops.push_back(N->getOperand(0));
    if (Glue.getNode())
      Ops.push_back(Glue);

    SDVTList VTs = CurDAG->getVTList(MVT::Other, MVT::Glue);
    SDNode *Result = CurDAG->getMachineNode(MYISA::CALL, DL, VTs, Ops);
    ReplaceNode(N, Result);
    return;
  }
  }

  // No custom match — try TableGen-generated patterns (SelectCode).
  // This handles all the simple cases: ADD_rrr, SUB_rrr, LOAD_reg, etc.
  SelectCode(N);
}

//===----------------------------------------------------------------------===//
// SelectAddr — Complex pattern implementation for memory addressing
//
// This function is called by the TableGen-generated ISel code whenever a
// memory instruction uses the "addr" ComplexPattern. It decomposes an address
// DAG node into a (Base, Offset) pair suitable for the LOAD_reg/STORE_reg
// instruction format: LOAD rd, [Base + Offset].
//
// Cases handled:
//   1. FrameIndex → (FI, 0) — stack-allocated variables
//   2. reg + const → (reg, const) — if constant fits in signed 16 bits
//   3. reg + reg → (reg, reg) — base + index (offset as register)
//   4. bare reg → (reg, 0) — pointer dereference with no offset
//===----------------------------------------------------------------------===//

bool MYISADAGToDAGISel::SelectAddr(SDValue Addr, SDValue &Base,
                                    SDValue &Offset) {
  // Case 1: Frame index (stack variable access)
  // Convert to TargetFrameIndex which will be replaced with SP+offset
  // during frame index elimination (MYISARegisterInfo::eliminateFrameIndex).
  if (FrameIndexSDNode *FIN = dyn_cast<FrameIndexSDNode>(Addr)) {
    Base = CurDAG->getTargetFrameIndex(FIN->getIndex(), MVT::i32);
    Offset = CurDAG->getTargetConstant(0, SDLoc(Addr), MVT::i32);
    return true;
  }

  if (Addr.getOpcode() == ISD::ADD) {
    if (auto *C = dyn_cast<ConstantSDNode>(Addr.getOperand(1))) {
      int64_t Value = C->getSExtValue();
      if (Value >= -32768 && Value <= 32767) {
        Base = Addr.getOperand(0);
        Offset = CurDAG->getTargetConstant(Value, SDLoc(Addr), MVT::i32);
        return true;
      }
    }
  }

  // TODO: recognise richer addressing modes so the compiler can fold address
  //       arithmetic into your load/store instructions. You may additionally
  //       match:
  //         - reg + constant  -> (Base = reg,  Offset = constant)  when the
  //           constant fits your instruction's offset field
  //         - reg + reg       -> (Base = reg,  Offset = index reg)
  //       Match ISD::ADD here and set Base/Offset accordingly before falling
  //       through to the bare-register case below.

  // Fallback: use the whole expression as the base with a zero offset.
  Base = Addr;
  Offset = CurDAG->getTargetConstant(0, SDLoc(Addr), MVT::i32);
  return true;
}

//===----------------------------------------------------------------------===//
// Factory function — Creates and returns the ISel pass instance.
// Called by MYISAPassConfig::addInstSelector() in MYISATargetMachine.cpp.
//===----------------------------------------------------------------------===//

FunctionPass *llvm::createMYISAISelDag(MYISATargetMachine &TM) {
  return new MYISADAGToDAGISel(TM, CodeGenOpt::Default);
}
