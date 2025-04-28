--
--  File Name:         TestHarness.vhd
--  Design Unit Name:  TestHarness
--  Revision:          OSVVM MODELS STANDARD VERSION
--
--  Maintainer:        Jim Lewis      email:  jim@synthworks.com
--  Contributor(s):
--     Jim Lewis      jim@synthworks.com
--
--
--  Description:
--      Test harness for Wishbone tests
--
--
--  Developed by:
--        SynthWorks Design Inc.
--        VHDL Training Classes
--        http://www.SynthWorks.com
--
--  Revision History:
--    Date      Version    Description
--    04/2025   2025       Initial revision
--
--
--  This file is part of OSVVM.
--  
--  Copyright (c) 2025 by SynthWorks Design Inc.  
--
--  Licensed under the Apache License, Version 2.0 (the "License");
--  you may not use this file except in compliance with the License.
--  You may obtain a copy of the License at
--
--      https://www.apache.org/licenses/LICENSE-2.0
--
--  Unless required by applicable law or agreed to in writing, software
--  distributed under the License is distributed on an "AS IS" BASIS,
--  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--  See the License for the specific language governing permissions and
--  limitations under the License.
--

library ieee ;
  use ieee.std_logic_1164.all ;
  use ieee.numeric_std.all ;
  use ieee.numeric_std_unsigned.all ;

library osvvm ;
  context osvvm.OsvvmContext ;

library OSVVM_WISHBONE ;
  context OSVVM_WISHBONE.WishboneContext ;

entity TestHarness is
end entity TestHarness ;
architecture Structural of TestHarness is
  constant ADDR_WIDTH : integer := 32 ;
  constant DATA_WIDTH : integer := 32 ;

  constant tperiod_Clk : time := 10 ns ;
  constant tpd         : time := 2 ns ;

  signal Clk         : std_logic ;
  signal nReset      : std_logic ;

  ------------------------------------------------------------
  -- Create Signal Declarations using local packages (aka the easy way)
  ------------------------------------------------------------
  package Manager is new OSVVM_WISHBONE.WishboneGenericSignalsPkg
    generic map (
      ADDR_WIDTH   => 32, 
      DATA_WIDTH   => 32
    ) ;

  package Subordinate is new OSVVM_WISHBONE.WishboneGenericSignalsPkg
    generic map (
      ADDR_WIDTH   => 32, 
      DATA_WIDTH   => 32
    ) ;

  ------------------------------------------------------------
  -- Component Declarations
  --   Only need one for TestCtrl
  --   Component declarations for OSVVM VC are in a package
  --   referenced by context OSVVM_WISHBONE.WishboneContext
  --
  component TestCtrl is
    port (
      -- Global Signal Interface
      nReset          : In    std_logic ;

      -- Transaction Interfaces
      ManagerRec      : inout AddressBusRecType ;
      SubordinateRec  : inout AddressBusRecType
    ) ;
  end component TestCtrl ;

begin

  ------------------------------------------------------------
  -- WishbonePassThru demonstrates how Wishbone VC connect to your DUT
  -- Actuals in port map are aliases declared in WishboneGenericSignalsPkg
  -- "Manager." is a selected path into the local package instance
  DUT_1 : WishbonePassThru 
  ------------------------------------------------------------
  port map (
      -- Manager Interface 
      --              Selected path to local subordinate package
      mCyc_o       => Subordinate.Cyc   ,
      mLock_o      => Subordinate.Lock  ,
      mStb_o       => Subordinate.Stb   ,
      mWe_o        => Subordinate.We    ,
      mAck_i       => Subordinate.Ack   ,
      mErr_i       => Subordinate.Err   ,
      mRty_i       => Subordinate.Rty   ,
      mStall_i     => Subordinate.Stall ,
      mAdr_o       => Subordinate.Adr   ,
      mDat_o       => Subordinate.iDat  ,
      mDat_i       => Subordinate.oDat  ,
      mSel_o       => Subordinate.Sel   ,
      mCti_o       => Subordinate.Cti   ,
  
      -- Subordinate Interface 
      --              Selected path to local manager package
      sCyc_i       => Manager.Cyc   ,
      sLock_i      => Manager.Lock  ,
      sStb_i       => Manager.Stb   ,
      sWe_i        => Manager.We    ,
      sAck_o       => Manager.Ack   ,
      sErr_o       => Manager.Err   ,
      sRty_o       => Manager.Rty   ,
      sStall_o     => Manager.Stall ,
      sAdr_i       => Manager.Adr   ,
      sDat_o       => Manager.iDat  ,
      sDat_i       => Manager.oDat  ,
      sSel_i       => Manager.Sel   ,
      sCti_i       => Manager.Cti
    ) ;
  
  -- create Clock
  CreateClock (
    Clk        => Clk,
    Period     => Tperiod_Clk
  )  ;

  -- create nReset
  CreateReset (
    Reset       => nReset,
    ResetActive => '0',
    Clk         => Clk,
    Period      => 7 * tperiod_Clk,
    tpd         => tpd
  ) ;

  ------------------------------------------------------------
  -- WishboneRegisterSubordinate
  --   Basic Register interface - supports read/write to internal registers
  --   Subordinate.WishboneBus is a selected path to signal 
  --   declared in Subordinate local package
  Subordinate_1 : WishboneRegisterSubordinate
  ------------------------------------------------------------
  generic map(
    WB_ADR         => (Subordinate.Adr'range => '-'),  -- for now match any address
    NUM_REGISTERS  => 16#400#  -- Address is bit-wise: AAAA AA--
  ) 
  port map (
    -- Globals
    Clk         => Clk,
    nReset      => nReset,

    -- AXI Manager Functional Interface
    WishboneBus => Subordinate.WishboneBus,

    -- Testbench Transaction Interface
    TransRec    => Subordinate.TransRec
  ) ;

  ------------------------------------------------------------
  -- WishboneManager Verification Component
  Manager_1 : WishboneManager
  ------------------------------------------------------------
  port map (
    -- Globals
    Clk         => Clk,
    nReset      => nReset,

    -- AXI Manager Functional Interface
    WishboneBus => Manager.WishboneBus,

    -- Testbench Transaction Interface
    TransRec    => Manager.TransRec
  ) ;


  ------------------------------------------------------------
  --  TestCtrl - test sequencer - architecture contains test cases
  TestCtrl_1 : TestCtrl
  ------------------------------------------------------------
  port map (
    -- Global Signal Interface
    nReset         => nReset,

    -- Transaction Interfaces
    ManagerRec     => Manager.TransRec,
    SubordinateRec => Subordinate.TransRec
  ) ;

end architecture Structural ;