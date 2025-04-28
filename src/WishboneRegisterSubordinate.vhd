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
    MODEL_ID_NAME    : string  := "" ;
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

  -- Derive ModelInstance label from path_name
  constant MODEL_INSTANCE_NAME : string :=
  -- use MODEL_ID_NAME Generic if set, otherwise use instance label (preferred if set as entityname_1)
      IfElse(MODEL_ID_NAME /= "", MODEL_ID_NAME, to_lower(PathTail(WishboneRegisterSubordinate'PATH_NAME))) ;

  constant MODEL_NAME : string := "WishboneRegisterSubordinate" ;

end WishboneRegisterSubordinate;

architecture VerificationComponent of WishboneRegisterSubordinate is
  signal Enable   : std_logic ;
  signal WrAck    : std_logic ;
  signal RdAck    : std_logic ;
  type   RegBankType is array(0 to NUM_REGISTERS-1) of std_logic_vector(WishboneBus.idat'range) ;
  signal RegBank : RegBankType ;

--  signal NormalizedAdr : std_logic_vector(ADDR_WIDTH-1 downto 0) ;
  alias NormalizedAdr  : std_logic_vector(ADDR_WIDTH-1 downto 0) is WishboneBus.Adr ; 
  alias NormalizediDat : std_logic_vector(DATA_WIDTH-1 downto 0) is WishboneBus.iDat ; 
  subtype RegisterAdrRange is natural range REGISTER_ADDR_WIDTH-1 downto BYTE_ADDR_WIDTH ;

  signal DelayValueSetting : integer := 0 ; 
  signal UseCoverageDelays : boolean := FALSE ; 
  signal DelayCovID : DelayCoverageIDType ; 
  signal ModelID    : AlertLogIDType ;

  signal Params : ModelParametersIDType ;

  -- Internal Resources
--  signal DataFifo        : osvvm.ScoreboardPkg_slv.ScoreboardIDType ;

begin
  ------------------------------------------------------------
  -- Turn off drivers not being driven by this model
  -- With a mode view, this is not necessary
  ------------------------------------------------------------
  InitWishboneRec (WishboneBusRec => WishboneBus) ;

  ------------------------------------------------------------
  --  Initialize alerts
  ------------------------------------------------------------
  Initialize : process
    variable ID : AlertLogIDType ;
    variable vParams : ModelParametersIDType ; 
  begin
    -- Alerts
    ID         := NewID(MODEL_INSTANCE_NAME) ;
    ModelID    <= ID ;
    
    vParams    := NewID("Wishbone Parameters", to_integer(OPTIONS_MARKER), ID) ; 
    InitAxiOptions(vParams) ;
    Params     <= vParams ; 

    -- FIFOs get an AlertLogID with NewID, however, it does not print in ReportAlerts (due to DoNotReport)
    --   FIFOS only generate usage type errors 
 --   DataFifo   <= NewID("DataFifo", ID, ReportMode => DISABLED, Search => PRIVATE_NAME);
    wait ;
  end process Initialize ;

  ------------------------------------------------------------
  --  Transaction Dispatcher
  --    Dispatches transactions to
  ------------------------------------------------------------
  TransactionDispatcher : process
    variable WishboneOption    : WishboneOptionsType ;
    variable WishboneOptionVal : integer ;

    variable Local  : WishboneBus'subtype ; 
    alias LocalAdr  : std_logic_vector(Local.Adr'length-1 downto 0) is Local.Adr ; 
    alias LocalByteAdr is LocalAdr(BYTE_ADDR_WIDTH -1 downto 0) ;

    variable ExpectedData    : std_logic_vector(WishboneBus.iDat'range) ;
  begin
    Local := InitWishboneRec (Local, '0') ;
    wait for 0 ns ; -- Allow ModelID to become valid
    TransRec.Params         <= Params ; 
--    TransRec.WriteBurstFifo <= NewID("WriteBurstFifo",      ModelID, Search => PRIVATE_NAME) ;
--    TransRec.ReadBurstFifo  <= NewID("ReadBurstFifo",       ModelID, Search => PRIVATE_NAME) ;
    DelayCovID   <= NewID("DelayCov",  ModelID, ReportMode => DISABLED) ;
    wait for 0 ns ;  
    AddBins (DelayCovID.BurstLengthCov,  GenBin(2,10,1)) ;
    AddBins (DelayCovID.BeatDelayCov,    GenBin(0)) ;
    AddBins (DelayCovID.BurstDelayCov,   GenBin(2,5,1)) ;
    
    DispatchLoop : loop
      WaitForTransaction(
         Clk      => Clk,
         Rdy      => TransRec.Rdy,
         Ack      => TransRec.Ack
      ) ;

      case TransRec.Operation is
        -- Execute Standard Directive Transactions
        -- when WAIT_FOR_TRANSACTION =>

        when WAIT_FOR_CLOCK =>
          WaitForClock(Clk, TransRec.IntToModel) ;

        when GET_ALERTLOG_ID =>
          TransRec.IntFromModel <= integer(ModelID) ;
          wait for 0 ns ; 

        when SET_USE_RANDOM_DELAYS =>        
          UseCoverageDelays      <= TransRec.BoolToModel ; 

        when GET_USE_RANDOM_DELAYS =>
          TransRec.BoolFromModel <= UseCoverageDelays ;

        when SET_DELAYCOV_ID =>
          DelayCovID <= GetDelayCoverage(TransRec.IntToModel) ;
          UseCoverageDelays <= TRUE ; 

        when GET_DELAYCOV_ID =>
          TransRec.IntFromModel <= DelayCovID.ID  ;
          UseCoverageDelays <= TRUE ; 

        when GET_TRANSACTION_COUNT =>
          TransRec.IntFromModel <= integer(TransRec.Rdy) ; --  WriteStartDoneCount + ReadStartDoneCount ;
          wait for 0 ns ; 
--          
        -- Model Configuration Options
        when SET_MODEL_OPTIONS =>
--           WishboneOption := WishboneOptionsType'val(TransRec.Options) ;
--           if IsAxiInterface(WishboneOption) then
--             SetWishboneInterfaceDefault(AxiDefaults, WishboneOption, TransRec.IntToModel) ;
--           else
--             Set(Params, TransRec.Options, TransRec.IntToModel) ;
--           end if ;
-- 
        when GET_MODEL_OPTIONS =>
--           WishboneOption := WishboneOptionsType'val(TransRec.Options) ;
--           if IsAxiInterface(WishboneOption) then
--             TransRec.IntFromModel <= GetWishboneInterfaceDefault(AxiDefaults, WishboneOption) ;
--           else
--             TransRec.IntFromModel <= Get(Params, TransRec.Options) ;
--           end if ;

        -- The End -- Done
        when others =>
          -- Signal multiple Driver Detect or not implemented transactions.
          Alert(ModelID, ClassifyUnimplementedOperation(TransRec), FAILURE) ;

      end case ;
    end loop DispatchLoop ;
  end process TransactionDispatcher ;

  ------------------------------------------------------------
  -- Decode and Combine 
  ------------------------------------------------------------
  Enable            <= WishboneBus.Adr ?= WB_ADR ;
  WishboneBus.Ack   <= WrAck or RdAck after tpd_Clk_Ack ; 
  WishboneBus.Rty   <= '0' ; 
  WishboneBus.Err   <= '0' ; 
  WishboneBus.Stall <= WishboneBus.Stb and not (WrAck or RdAck) after tpd_Clk_Stall ; 
 
  ------------------------------------------------------------
  -- Write to Register Bank
  ------------------------------------------------------------
  WriteProc : process 
    variable intRegisterAdr : integer ; 
    variable Offset : integer ; 
    variable DelayCycles : integer ; 
  begin
    WrAck <= '0' ; 
    WriteLoop : loop 
      wait until rising_edge(Clk) and Enable = '1' and WishboneBus.Stb = '1' and WishboneBus.We = '1' ; 
      intRegisterAdr := to_integer(NormalizedAdr(RegisterAdrRange)) ;
      if intRegisterAdr < NUM_REGISTERS then 
        for i in 0 to SEL_WIDTH-1 loop 
          if WishboneBus.Sel(i) = '1' then 
            Offset := i * 8 ; 
            RegBank(intRegisterAdr)(Offset + 7 downto Offset) <= NormalizediDat(Offset + 7 downto Offset) ; 
          end if ; 
        end loop ;
      else
        -- if NUM_REGISTERS is 2**n this will never happen
        Alert(ModelID, "Write Address: " & to_string(intRegisterAdr) & " is too big.", FAILURE) ;
      end if ; 

      DelayCycles := GetRandDelay(DelayCovID) when UseCoverageDelays else DelayValueSetting ; 
      WaitForClock(Clk, DelayCycles) ; 
      WrAck <= '1' ; 
      WaitForClock(Clk) ;
      WrAck <= '0' ; 
    end loop WriteLoop ; 
  end process WriteProc ;

  ------------------------------------------------------------
  -- Read from Register Bank
  ------------------------------------------------------------
  ReadProc : process 
    variable intRegisterAdr : integer ; 
    variable DelayCycles : integer ; 
  begin
    RdAck <= '0' ; 
    ReadLoop : loop 
      wait until rising_edge(Clk) and Enable = '1' and WishboneBus.Stb = '1' and WishboneBus.We = '0' ; 
      intRegisterAdr := to_integer(NormalizedAdr(RegisterAdrRange)) ;
    --       intRegisterAdr := to_integer(RegisterAdr) ;
      if intRegisterAdr < NUM_REGISTERS then 
        WishboneBus.oDat <= RegBank(intRegisterAdr) ; 
      else
        -- if NUM_REGISTERS is 2**n this will never happen
        Alert(ModelID, "Read Address: " & to_string(intRegisterAdr) & " is too big.", FAILURE) ;
      end if ;

      DelayCycles := GetRandDelay(DelayCovID) when UseCoverageDelays else DelayValueSetting ; 
      WaitForClock(Clk, DelayCycles) ; 
      RdAck <= '1' ; 
      WaitForClock(Clk) ;
      RdAck <= '0' ; 
    end loop ReadLoop ; 
  end process ReadProc ;
end VerificationComponent ;
