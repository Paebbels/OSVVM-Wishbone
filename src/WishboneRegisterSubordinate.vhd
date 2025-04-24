--
--  File Name:         WishboneRegisterSubordinate.vhd
--  Design Unit Name:  WishboneRegisterSubordinate
--  Revision:          OSVVM MODELS STANDARD VERSION
--
--  Maintainer:        Jim Lewis      email:  jim@synthworks.com
--  Contributor(s):
--     Jim Lewis      jim@synthworks.com
--
--
--  Description:
--      Wishbone Register Subordinate
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
  use ieee.math_real.all ;

library osvvm ;
  context osvvm.OsvvmContext ;
--  use osvvm.ScoreboardPkg_slv.all ;

library osvvm_common ;
  context osvvm_common.OsvvmCommonContext ;

  use work.WishboneOptionsPkg.all ;
  use work.WishboneInterfacePkg.all ;
  use work.WishboneModelPkg.all ;

entity WishboneRegisterSubordinate is
  generic (
    WB_ADR           : std_logic_vector ;
    NUM_REGISTERS    : integer := 8 ;
    DEFAULT_DELAY    : time   := 1 ns ;
    tpd_Clk_Ack      : time   := DEFAULT_DELAY ;
    tpd_Clk_Stall    : time   := DEFAULT_DELAY  
  ) ;
  port (
    Clk             : in    std_logic ;
    nReset          : in    std_logic ;

    -- Wishbone Bus
    WishboneBus     : inout WishboneRecType ;
    
    -- Testbench Transaction Interface
    TransRec      : inout AddressBusRecType 
  ) ;
  constant ADDR_WIDTH : integer := WishboneBus.Adr'length ; 
  constant DATA_WIDTH : integer := WishboneBus.oDat'length ;  
  constant SEL_WIDTH  : integer := WishboneBus.Sel'length ; 
  constant BYTE_ADDR_WIDTH     : integer := integer(ceil(log2(real(SEL_WIDTH)))) ;
  constant REGISTER_ADDR_WIDTH : integer := integer(ceil(log2(real(NUM_REGISTERS)))) ;

end WishboneRegisterSubordinate;

architecture VerificationComponent of WishboneRegisterSubordinate is
  signal Enable   : std_logic ;
  signal WrAck    : std_logic ;
  signal RdAck    : std_logic ;
  type   RegBankType is array(0 to NUM_REGISTERS-1) of std_logic_vector(WishboneBus.idat'range) ;
  signal RegBank : RegBankType ;

--  signal NormalizedAdr : std_logic_vector(ADDR_WIDTH-1 downto 0) ;
  alias NormalizedAdr : std_logic_vector(ADDR_WIDTH-1 downto 0) is WishboneBus.Adr ; 
  alias NormalizediDat : std_logic_vector(DATA_WIDTH-1 downto 0) is WishboneBus.iDat ; 
  subtype RegisterAdrRange is natural range REGISTER_ADDR_WIDTH-1 downto BYTE_ADDR_WIDTH ;

begin
  ------------------------------------------------------------
  -- Turn off drivers not being driven by this model
  -- With a mode view, this is not necessary
  ------------------------------------------------------------
  InitWishboneRec (WishboneBusRec => WishboneBus) ;

  ------------------------------------------------------------
  -- Decode and Combine 
  ------------------------------------------------------------
  Enable            <= WishboneBus.Adr ?= WB_ADR ;
  WishboneBus.Ack   <= WrAck or RdAck after tpd_Clk_Ack ; 
  WishboneBus.Stall <= WishboneBus.Stb and not (WrAck or RdAck) after tpd_Clk_Stall ; 
 
  ------------------------------------------------------------
  -- Write to Register Bank
  ------------------------------------------------------------
  process (Clk)
    variable intRegisterAdr : integer ; 
    variable Offset : integer ; 
  begin
    if rising_edge(Clk) then
      if Enable and WishboneBus.Stb and WishboneBus.We and not WrAck then
        intRegisterAdr := to_integer(NormalizedAdr(RegisterAdrRange)) ;
--        intRegisterAdr := to_integer(RegisterAdr) ;
        if intRegisterAdr < NUM_REGISTERS then 
          for i in 0 to SEL_WIDTH-1 loop 
            if WishboneBus.Sel(i) = '1' then 
              Offset := i * 8 ; 
              RegBank(intRegisterAdr)(Offset + 7 downto Offset) <= NormalizediDat(Offset + 7 downto Offset) ; 
            end if ; 
          end loop ;
        else
          -- if NUM_REGISTERS is 2**n this will never happen
          Alert(WishboneRegisterSubordinate'path_name & 
            " Write Register Address = " & to_string(intRegisterAdr) & " is too big. ", 
            FAILURE) ;
        end if ; 
        WrAck <= '1' ;
      else
        WrAck <= '0' ;
      end if ; 
    end if;
  end process;

  ------------------------------------------------------------
  -- Read from Register Bank
  ------------------------------------------------------------
  process (Clk)
    variable intRegisterAdr : integer ; 
  begin
    if rising_edge(Clk) then
      if Enable and WishboneBus.Stb and not WishboneBus.We and not RdAck then
        intRegisterAdr := to_integer(NormalizedAdr(RegisterAdrRange)) ;
 --       intRegisterAdr := to_integer(RegisterAdr) ;
        if intRegisterAdr < NUM_REGISTERS then 
          WishboneBus.oDat <= RegBank(intRegisterAdr) ; 
        else
          -- if NUM_REGISTERS is 2**n this will never happen
          Alert(WishboneRegisterSubordinate'path_name & 
            " Read Register Address = " & to_string(intRegisterAdr) & " is too big. ", 
            FAILURE) ;
        end if ; 
        RdAck <= '1' ;
      else
        WishboneBus.oDat <= (WishboneBus.oDat'range => 'X') ; 
        RdAck <= '0' ;
      end if ; 
    end if;
  end process;
end VerificationComponent ;


