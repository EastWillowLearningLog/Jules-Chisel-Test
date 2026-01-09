package blinky

import chisel3._
import chisel3.util._
import chisel3.stage.ChiselStage

/**
 * Blinky module that toggles an LED at 1Hz given a 100MHz clock.
 *
 * @param freq Clock frequency in Hz (default 100MHz)
 */
class Blinky(freq: Int = 100000000) extends Module {
  val io = IO(new Bundle {
    val led0 = Output(Bool()) // Using led0 to match typical single LED usage
  })

  // Calculate the toggle threshold (0.5 seconds)
  // freq = cycles per second. 0.5s = freq / 2
  val CNT_MAX = (freq / 2 - 1).U

  val cntReg = RegInit(0.U(32.W))
  val blkReg = RegInit(false.B)

  cntReg := cntReg + 1.U
  when(cntReg === CNT_MAX) {
    cntReg := 0.U
    blkReg := !blkReg
  }

  io.led0 := blkReg
}

object BlinkyMain extends App {
  // Generate Verilog
  // Using ChiselStage to emit Verilog to the 'generated' directory
  (new ChiselStage).emitVerilog(
    new Blinky(100000000),
    Array(
      "--target-dir", "generated"
    )
  )
}
