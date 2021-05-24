// 
// Copyright 2021 OpenHW Group
// Copyright 2021 Datum Technology Corporation
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// 
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// 
//     https://solderpad.org/licenses/SHL-2.1/
// 
// Unless required by applicable law or agreed to in writing, any work
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.
// 


`ifndef __UVME_CV32E40P_VP_VSEQ_SV__
`define __UVME_CV32E40P_VP_VSEQ_SV__


/**
 * Virtual sequence implementing the cv32e40p virtual peripherals.
 * TODO Move most of the functionality to a cv32e env base class.
 */
class uvme_cv32e40p_vp_vseq_c extends uvme_cv32e40p_base_vseq_c;
   
   // Fields
   rand int unsigned      cycle_counter_frequency; ///< Measured in picoseconds
        longint unsigned  cycle_counter = 0;
        event             interrupt_timer_start;
        int unsigned      interrupt_timer_value;
   rand int unsigned      max_latency;
        int unsigned      signature_start_address;
        int unsigned      signature_end_address;
   
   
   `uvm_object_utils_begin(uvme_cv32e40p_vp_vseq_c)
      `uvm_field_int(cycle_counter_frequency, UVM_DEFAULT + UVM_DEC)
      `uvm_field_int(cycle_counter          , UVM_DEFAULT + UVM_DEC)
      `uvm_field_int(interrupt_timer_value  , UVM_DEFAULT + UVM_DEC)
      `uvm_field_int(max_latency            , UVM_DEFAULT + UVM_DEC)
      `uvm_field_int(signature_start_address, UVM_DEFAULT          )
      `uvm_field_int(signature_end_address  , UVM_DEFAULT          )
   `uvm_object_utils_end
   
   
   /**
    * Describe defaults_cons
    */
   constraint defaults_cons {
      /*soft*/ cycle_counter_frequency == 10_000; // 10ns = 100 Mhz
      /*soft*/ max_latency == 10;
   }
   
   
   /**
    * Default constructor.
    */
   extern function new(string name="uvme_cv32e40p_vp_vseq");
   
   /**
    * TODO Describe uvme_cv32e40p_vp_vseq_c::body()
    */
   extern virtual task body();
   
   /**
    * TODO Describe uvme_cv32e40p_vp_vseq_c::do_response()
    */
   extern virtual task do_response(ref uvma_obi_memory_mon_trn_c mon_req);
   
   /**
    * TODO Describe uvme_cv32e40p_vp_vseq_c::vp_address_range_check()
    */
   extern virtual task vp_address_range_check(ref uvma_obi_memory_mon_trn_c mon_req);
   
   /**
    * TODO Describe uvme_cv32e40p_vp_vseq_c::vp_virtual_printer()
    */
   extern virtual task vp_virtual_printer(ref uvma_obi_memory_mon_trn_c mon_req);
   
   /**
    * TODO Describe uvme_cv32e40p_vp_vseq_c::vp_interrupt_timer_control()
    */
   extern virtual task vp_interrupt_timer_control(ref uvma_obi_memory_mon_trn_c mon_req);
   
   /**
    * TODO Describe uvme_cv32e40p_vp_vseq_c::vp_debug_control()
    */
   extern virtual task vp_debug_control(ref uvma_obi_memory_mon_trn_c mon_req);
   
   /**
    * TODO Describe uvme_cv32e40p_vp_vseq_c::(vp_rand_num_gen)
    */
   extern virtual task vp_rand_num_gen(ref uvma_obi_memory_mon_trn_c mon_req);
   
   /**
    * TODO Describe uvme_cv32e40p_vp_vseq_c::vp_cycle_counter()
    */
   extern virtual task vp_cycle_counter(ref uvma_obi_memory_mon_trn_c mon_req);
   
   /**
    * TODO Describe uvme_cv32e40p_vp_vseq_c::vp_instr_mem_intf_stall_ctrl()
    */
   extern virtual task vp_instr_mem_intf_stall_ctrl(ref uvma_obi_memory_mon_trn_c mon_req);
   
   /**
    * TODO Describe uvme_cv32e40p_vp_vseq_c::vp_vp_status_flags()
    */
   extern virtual task vp_vp_status_flags(ref uvma_obi_memory_mon_trn_c mon_req);
   
   /**
    * TODO Describe uvme_cv32e40p_vp_vseq_c::vp_sig_writer()
    */
   extern virtual task vp_sig_writer(ref uvma_obi_memory_mon_trn_c mon_req);
   
   /**
    * TODO Describe uvme_cv32e40p_vp_vseq_c::irq_o()
    */
   extern virtual task irq_o();
   
   /**
    * TODO Describe uvme_cv32e40p_vp_vseq_c::add_latencies()
    */
   extern virtual function void add_latencies(ref uvma_obi_memory_slv_seq_item_c slv_rsp);
   
endclass : uvme_cv32e40p_vp_vseq_c


function uvme_cv32e40p_vp_vseq_c::new(string name="uvme_cv32e40p_vp_vseq");
   
   super.new(name);
   
endfunction : new


task uvme_cv32e40p_vp_vseq_c::body();
   
   uvma_obi_memory_mon_trn_c  mon_trn;
   
   fork
      begin
         forever begin
            // Wait for the monitor to send us the mstr's "req" with an access request
            p_sequencer.obi_memory_data_sqr.mon_trn_fifo.get(mon_trn);
            `uvm_info("OBI_MEMORY_SLV_SEQ", $sformatf("Got mon_trn:\n%s", mon_trn.sprint()), UVM_HIGH)
            do_response(mon_trn);
         end
      end
      
      begin
         forever begin
            #(cycle_counter_frequency * 1ps);
            cycle_counter++;
         end
      end
      
      begin
         forever begin
            @interrupt_timer_start;
            fork
               begin
                  while (interrupt_timer_value > 0) begin
                     @(cntxt.obi_memory_cntxt.vif.clk);
                     interrupt_timer_value--;
                  end
                  irq_o();
               end
               
               begin
                  @interrupt_timer_start;
               end
            join_any
            disable fork;
         end
      end
   join_none
   
endtask : body


task uvme_cv32e40p_vp_vseq_c::do_response(ref uvma_obi_memory_mon_trn_c mon_req);
   
   bit  vp_handled = 1;
   
   case(mon_req.address)
      32'h1000_0000               : vp_virtual_printer          (mon_req);
      32'h1500_0000, 32'h1500_0004: vp_interrupt_timer_control  (mon_req);
      32'h1500_0008               : vp_debug_control            (mon_req);
      32'h1500_1000               : vp_rand_num_gen             (mon_req);
      32'h1500_1004               : vp_cycle_counter            (mon_req);
      32'h1600_????               : vp_instr_mem_intf_stall_ctrl(mon_req);
      32'h2000_0000, 32'h2000_0004: vp_vp_status_flags          (mon_req);
      32'h2000_0008, 32'h2000_000C,
      32'h2000_0010               : vp_sig_writer               (mon_req);
      
      default: begin
         vp_handled = 0;
      end
   endcase
   
   if (!vp_handled) begin
      if (mon_req.address >= 2**20) begin
         vp_address_range_check(mon_req);
      end
   end
   
endtask : do_response


task uvme_cv32e40p_vp_vseq_c::vp_address_range_check(ref uvma_obi_memory_mon_trn_c mon_req);

   uvma_obi_memory_slv_seq_item_c  slv_rsp;
   
   `uvm_create  (slv_rsp)
   add_latencies(slv_rsp);
   
   if (mon_req.access_type == UVMA_OBI_MEMORY_ACCESS_WRITE) begin
      `uvm_info("OBI_VP", $sformatf("Call to virtual peripheral 'address_range_check:\n'", mon_req.sprint()), UVM_LOW)
      slv_rsp.start(p_sequencer.obi_memory_sqr);
      `uvm_fatal("VP_VSEQ", $sformatf("Ending simulation due to:\n%s", mon_req.sprint()))
   end
   else begin
      slv_rsp.start(p_sequencer.obi_memory_sqr);
   end
   
endtask : vp_address_range_check


task uvme_cv32e40p_vp_vseq_c::vp_virtual_printer(ref uvma_obi_memory_mon_trn_c mon_req);

   uvma_obi_memory_slv_seq_item_c  slv_rsp;
   
   `uvm_create  (slv_rsp)
   add_latencies(slv_rsp);
   
   if (mon_req.access_type == UVMA_OBI_MEMORY_ACCESS_WRITE) begin
      `uvm_info("OBI_VP", $sformatf("Call to virtual peripheral 'virtual_printer:\n'", mon_req.sprint()), UVM_LOW)
      $write("%c", mon_req.data[7:0]);
   end
   
   slv_rsp.start(p_sequencer.obi_memory_sqr);
   
endtask : vp_virtual_printer


task uvme_cv32e40p_vp_vseq_c::vp_interrupt_timer_control(ref uvma_obi_memory_mon_trn_c mon_req);
   
   uvma_obi_memory_slv_seq_item_c  slv_rsp;
   
   `uvm_create  (slv_rsp)
   add_latencies(slv_rsp);
   
   if (mon_req.access_type == UVMA_OBI_MEMORY_ACCESS_WRITE) begin
      `uvm_info("OBI_VP", $sformatf("Call to virtual peripheral 'interrupt_timer_control:\n'", mon_req.sprint()), UVM_LOW)
      interrupt_timer_value = mon_req.data;
      ->interrupt_timer_start;
   end
   
   slv_rsp.start(p_sequencer.obi_memory_sqr);
   
endtask : vp_interrupt_timer_control


task uvme_cv32e40p_vp_vseq_c::vp_debug_control(ref uvma_obi_memory_mon_trn_c mon_req);
   
   uvma_obi_memory_slv_seq_item_c  slv_rsp;
   uvma_debug_seq_item_c  dbg_req;
   bit                    request_mode        = 0;
   bit                    dbg_req_value       = 0;
   bit                    rand_pulse_duration = 0;
   bit                    rand_start_delay    = 0;
   int unsigned           dbg_pulse_duration  = 0;
   
   `uvm_create  (slv_rsp)
   add_latencies(slv_rsp);
   
   if (mon_req.access_type == UVMA_OBI_MEMORY_ACCESS_WRITE) begin
      `uvm_info("OBI_VP", $sformatf("Call to virtual peripheral 'interrupt_timer_control:\n'", mon_req.sprint()), UVM_LOW)
      
      // Extract fields from write data
      dbg_req_value       = mon_req.data[31];
      request_mode        = mon_req.data[30];
      rand_pulse_duration = mon_req.data[29];
      dbg_pulse_duration  = mon_req.data[28:16];
      rand_start_delay    = mon_req.data[15];
      start_delay         = mon_req.data[14:0];
      
      // Start debug pulse
      fork
         begin
            if (rand_start_delay) begin
               #($urandom_range(0, start_delay) * 1ns);
            end
            else begin
               #(start_delay * 1ns);
            end
            
            if (request_mode) begin
               cntxt.misc_vif.debugger_wdata = dbg_req_value;
               if (rand_pulse_duration) begin
                  #($urandom_range(0, g_pulse_duration) * 1ns);
               end
               else begin
                  #(dbg_pulse_duration * 1ns);
               end
               cntxt.misc_vif.debugger_wdata = !dbg_req_value;
            end
            else begin
               cntxt.misc_vif.debugger_wdata = dbg_req_value;
            end
         end
      join_none
   end
   
   slv_rsp.start(p_sequencer.obi_memory_sqr);
   
endtask : vp_debug_control


task uvme_cv32e40p_vp_vseq_c::vp_rand_num_gen(ref uvma_obi_memory_mon_trn_c mon_req);

   uvma_obi_memory_slv_seq_item_c  slv_rsp;
   
   `uvm_create  (slv_rsp)
   add_latencies(slv_rsp);
   
   if (mon_req.access_type == UVMA_OBI_MEMORY_ACCESS_READ) begin
      `uvm_info("OBI_VP", $sformatf("Call to virtual peripheral 'rand_num_gen:\n'", mon_req.sprint()), UVM_LOW)
      slv_rsp.rdata          = $urandom();
   end
   
   slv_rsp.start(p_sequencer.obi_memory_sqr);
   
endtask : vp_rand_num_gen


task uvme_cv32e40p_vp_vseq_c::vp_cycle_counter(ref uvma_obi_memory_mon_trn_c mon_req);

   uvma_obi_memory_slv_seq_item_c  slv_rsp;
   
   `uvm_create  (slv_rsp)
   add_latencies(slv_rsp);
   `
   uvm_info("OBI_VP", $sformatf("Call to virtual peripheral 'cycle_counter:\n'", mon_req.sprint()), UVM_LOW)
   
   if (mon_req.access_type == UVMA_OBI_MEMORY_ACCESS_READ) begin
      slv_rsp.rdata = cycle_counter;
      slv_rsp.start(p_sequencer.obi_memory_sqr);
   end
   else if (mon_req.access_type == UVMA_OBI_MEMORY_ACCESS_WRITE) begin
      cycle_counter = 0;
   end
   
   slv_rsp.start(p_sequencer.obi_memory_sqr);
   
endtask : vp_cycle_counter


task uvme_cv32e40p_vp_vseq_c::vp_instr_mem_intf_stall_ctrl(ref uvma_obi_memory_mon_trn_c mon_req);

   uvma_obi_memory_slv_seq_item_c  slv_rsp;
   
   `uvm_create  (slv_rsp)
   add_latencies(slv_rsp);
   
   if (mon_req.access_type == UVMA_OBI_MEMORY_ACCESS_WRITE) begin
      `uvm_info("OBI_VP", $sformatf("Call to virtual peripheral 'mem_intf_stall_ctrl:\n'", mon_req.sprint()), UVM_LOW)
      cntxt.instr_mem_delay_enabled = 1;
   end
   
   slv_rsp.start(p_sequencer.obi_memory_sqr);
   
endtask : vp_instr_mem_intf_stall_ctrl


task uvme_cv32e40p_vp_vseq_c::vp_vp_status_flags(ref uvma_obi_memory_mon_trn_c mon_req);

   uvma_obi_memory_slv_seq_item_c  slv_rsp;
   
   `uvm_create  (slv_rsp)
   add_latencies(slv_rsp);
   
   if (mon_req.access_type == UVMA_OBI_MEMORY_ACCESS_WRITE) begin
      `uvm_info("OBI_VP", $sformatf("Call to virtual peripheral 'vp_status_flags:\n'", mon_req.sprint()), UVM_LOW)
      if (mon_req.address == 32'h2000_0000) begin
         if (mon_req.data == ’d123456789) begin
            wait(cntxt.misc_vif.clk === 1);
            cntxt.misc_vif.tests_passed = 1;
            wait(cntxt.misc_vif.clk === 0);
            cntxt.misc_vif.tests_passed = 0;
         end
         else if (mon_req.data == ’d1)
            wait(cntxt.misc_vif.clk === 1);
            cntxt.misc_vif.tests_failed = 1;
            wait(cntxt.misc_vif.clk === 0);
            cntxt.misc_vif.tests_failed = 0;
         end
      end
      else if (mon_req.address == 32'h2000_0004) begin
         wait(cntxt.misc_vif.clk === 1);
         cntxt.misc_vif.exit_valid = 1;
         cntxt.misc_vif.exit_value = mon_req.data;
         wait(cntxt.misc_vif.clk === 0);
         cntxt.misc_vif.exit_valid = 0;
         cntxt.misc_vif.exit_value = 0;
      end
   end
   
   slv_rsp.start(p_sequencer.obi_memory_sqr);
   
endtask : vp_vp_status_flags


task uvme_cv32e40p_vp_vseq_c::vp_sig_writer(ref uvma_obi_memory_mon_trn_c mon_req);

   uvma_obi_memory_slv_seq_item_c  slv_rsp;
   string                          sig_file     = "";
   int                             sig_fd       = 0;
   bit                             use_sig_file = 0;
   
   `uvm_create  (slv_rsp)
   add_latencies(slv_rsp);
   
   if ($value$plusargs("signature=%s", sig_file)) begin
      sig_fd = $fopen(sig_file, "w");
      if (sig_fd == 0) begin
          `uvm_error("OBI_VP", $sformatf("Could not open file %s for writing", sig_file));
          use_sig_file = 0;
      end
      else begin
          use_sig_file = 1;
      end
   end
   
   if (mon_req.access_type == UVMA_OBI_MEMORY_ACCESS_WRITE) begin
      `uvm_info("OBI_VP", $sformatf("Call to virtual peripheral 'sig_writer:\n'", mon_req.sprint()), UVM_LOW)
      if (mon_req.address == 32'h2000_0008) begin
         signature_start_address = mon_req.data;
      end
      else if (mon_req.address == 32'h2000_000C) begin
         signature_end_address = mon_req.data;
      end
      else if (mon_req.address == 32'h2000_0010) begin
         for (int unsigned ii=signature_start_address; ii<signature_end_address; ii++) begin
            `uvm_info("OBI_VP", "Dumping signature", UVM_NONE)
            if (use_sig_file) begin
               $fdisplay(sig_fd, "%x%x%x%x", env_ctnxt.mem.mem[addr+3], env_ctnxt.mem.mem[addr+2], env_ctnxt.mem.mem[addr+1], env_ctnxt.mem.mem[addr+0]);
            end
            else begin
               `uvm_info("OBI_VP", $sformatf("%x%x%x%x", env_ctnxt.mem[ii+3], env_ctnxt.mem[ii+2], env_ctnxt.mem[ii+1], env_ctnxt.mem[ii+0]), UVM_NONE)
            end
         end
      end
   end
   
   slv_rsp.start(p_sequencer.obi_memory_sqr);
   
endtask : vp_sig_writer


task uvme_cv32e40p_vp_vseq_c::irq_o();
   
   wait (cntxt.misc_vif.clk === 1);
   cntxt.misc_vif.irq_o = 1;
   
endtask : irq_o


function void uvme_cv32e40p_vp_vseq_c::add_latencies(ref uvma_obi_memory_slv_seq_item_c slv_rsp);
   
   if (cntxt.instr_mem_delay_enabled) begin
      slv_rsp.gnt_latency    = $urandom_range(1,max_latency);
      slv_rsp.access_latency = $urandom_range(1,max_latency);
      slv_rsp.hold_duration  = $urandom_range(1,max_latency);
      slv_rsp.tail_length    = $urandom_range(1,max_latency);
   end
   else begin
      slv_rsp.gnt_latency    = 1;
      slv_rsp.access_latency = 1;
      slv_rsp.hold_duration  = 1;
      slv_rsp.tail_length    = 1;
   end
   
endfunction : add_latencies


`endif // __UVME_CV32E40P_VP_VSEQ_SV__
