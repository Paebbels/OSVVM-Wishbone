--
--  File Name:         WishboneComponentPkg.vhd
--  Design Unit Name:  WishboneComponentPkg
--  Revision:          OSVVM MODELS STANDARD VERSION
--
--  Maintainer:        Jim Lewis      email:  jim@synthworks.com
--  Contributor(s):
--     Jim Lewis      jim@synthworks.com
--
--
--  Description:
--      Package for Wishbone Components
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

library osvvm_common ;
  context osvvm_common.OsvvmCommonContext ;

  use work.WishboneInterfacePkg.all ;

package WishboneComponentPkg is

  ------------------------------------------------------------
  component WishboneManager is
  ------------------------------------------------------------
  generic (
      MODEL_ID_NAME      : string  := "" ;
      WISHBONE_PIPELINED : boolean := TRUE ;
      
      DEFAULT_DELAY      : time   := 1 ns ;
      tpd_Clk_Adr        : time   := DEFAULT_DELAY ; 
      tpd_Clk_oDat       : time   := DEFAULT_DELAY ; 
      tpd_Clk_Stb        : time   := DEFAULT_DELAY ; 
      tpd_Clk_Cyc        : time   := DEFAULT_DELAY ; 
      tpd_Clk_Cti        : time   := DEFAULT_DELAY ; 
      tpd_Clk_We         : time   := DEFAULT_DELAY ; 
      tpd_Clk_Sel        : time   := DEFAULT_DELAY ;
      tpd_Clk_Lock       : time   := DEFAULT_DELAY  
    ) ;
    port (
      -- Globals
      Clk           : in   std_logic ;
      nReset        : in   std_logic ;
    
      -- AXI Manager Functional Interface
      WishboneBus   : inout WishboneRecType ;
    
      -- Testbench Transaction Interface
      TransRec      : inout AddressBusRecType 
    ) ;
  end component WishboneManager ;

  ------------------------------------------------------------
  component WishboneRegisterSubordinate is
  ------------------------------------------------------------
    generic (
      MODEL_ID_NAME    : string  := "" ;
      MEMORY_NAME      : string  := "" ;
      WB_ADDR          : std_logic_vector := "-" & X"--_----" ; -- Default 8M words divided between Register, Memory, DMA
      REGISTER_ADDR    : std_logic_vector := "0" & X"00_----" ; -- Default 1K words of register 
      MEMORY_ADDR      : std_logic_vector := "1" & X"--_----" ; -- Default 4M words 
      DMA_WRITE_ADDR   : std_logic_vector := "0" & X"F0_0000" ;  
      DMA_READ_ADDR    : std_logic_vector := "0" & X"F0_0000" ;  
      
      DEFAULT_DELAY    : time    := 1 ns ;
      tpd_Clk_Ack      : time    := DEFAULT_DELAY ;
      tpd_Clk_Stall    : time    := DEFAULT_DELAY  
    ) ;
    port (
      Clk             : in    std_logic ;
      nReset          : in    std_logic ;

      -- Wishbone Bus
      WishboneBus     : inout WishboneRecType ;
      
      -- Testbench Transaction Interface
      TransRec      : inout AddressBusRecType 
      ) ;
    end component WishboneRegisterSubordinate;

  ------------------------------------------------------------
  component WishbonePassThru is
  ------------------------------------------------------------
    port (
      -- Manager Interface 
      mCyc_o       : out std_logic ; 
      mLock_o      : out std_logic ; 
      mStb_o       : out std_logic ; 
      mWe_o        : out std_logic ; 
      mAck_i       : in  std_logic ; 
      mErr_i       : in  std_logic ; 
      mRty_i       : in  std_logic ; 
      mStall_i     : in  std_logic ; 
      mAdr_o       : out std_logic_vector ; 
      mDat_o       : out std_logic_vector ; 
      mDat_i       : in  std_logic_vector ; 
      mSel_o       : out std_logic_vector ; 
      mCti_o       : out std_logic_vector(2 downto 0) ;
  
      -- Subordinate Interface 
      sCyc_i       : in  std_logic ; 
      sLock_i      : in  std_logic ; 
      sStb_i       : in  std_logic ; 
      sWe_i        : in  std_logic ; 
      sAck_o       : out std_logic ; 
      sErr_o       : out std_logic ; 
      sRty_o       : out std_logic ; 
      sStall_o     : out std_logic ; 
      sAdr_i       : in  std_logic_vector ; 
      sDat_o       : out std_logic_vector ; 
      sDat_i       : in  std_logic_vector ; 
      sSel_i       : in  std_logic_vector ; 
      sCti_i       : in  std_logic_vector(2 downto 0) 
    ) ;
  end component WishbonePassThru ;  
end package WishboneComponentPkg ;

