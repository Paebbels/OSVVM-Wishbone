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
  use osvvm.ScoreboardPkg_slv.all ;

library osvvm_common ;
  context osvvm_common.OsvvmCommonContext ;

  use work.WishboneOptionsPkg.all ;
  use work.WishboneInterfacePkg.all ;
  use work.WishboneModelPkg.all ;

entity WishboneRegisterSubordinate is
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

  -- Derive ModelInstance label from path_name
  constant MODEL_INSTANCE_NAME : string :=
      -- use MODEL_ID_NAME Generic if set, otherwise use instance label (preferred if set as entityname_1)
      IfElse(MODEL_ID_NAME /= "", MODEL_ID_NAME, to_lower(PathTail(WishboneRegisterSubordinate'PATH_NAME))) ;

  constant MODEL_NAME : string := "WishboneRegisterSubordinate" ;

  constant LOCAL_MEMORY_NAME : string := 
    IfElse(MEMORY_NAME /= "", MEMORY_NAME, MODEL_INSTANCE_NAME & ":memory") ;
  
  constant ADDR_WIDTH            : integer := WishboneBus.Adr'length ; 
  alias    NormalizedAddr        : std_logic_vector(ADDR_WIDTH-1 downto 0) is WishboneBus.Adr ; 
  constant NORM_WB_ADDR          : std_logic_vector := resize(WB_ADDR,        ADDR_WIDTH) ;
  constant NORM_REGISTER_ADDR    : std_logic_vector := resize(REGISTER_ADDR,  ADDR_WIDTH) ; -- Default 1K of register 
  constant NORM_MEMORY_ADDR      : std_logic_vector := resize(MEMORY_ADDR,    ADDR_WIDTH) ; -- Default 4M words - non-overlapping
  constant NORM_DMA_WRITE_ADDR   : std_logic_vector := resize(DMA_WRITE_ADDR, ADDR_WIDTH) ; 
  constant NORM_DMA_READ_ADDR    : std_logic_vector := resize(DMA_READ_ADDR,  ADDR_WIDTH) ;

  constant DATA_WIDTH            : integer := WishboneBus.oDat'length ;  
  subtype  WishboneDataBusType   is std_logic_vector(DATA_WIDTH-1 downto 0) ;
  alias    NormalizediDat        : WishboneDataBusType is WishboneBus.iDat ; 
  constant DATA_NUM_BYTES       : integer := DATA_WIDTH / 8 ;  
  constant SEL_WIDTH             : integer := WishboneBus.Sel'length ;
  constant BYTE_ADDR_WIDTH       : integer := integer(ceil(log2(real(DATA_NUM_BYTES)))) ;

  constant WORD_ADDR_WIDTH       : integer := ADDR_WIDTH - BYTE_ADDR_WIDTH ;
  subtype  WordAddrRange is natural range WORD_ADDR_WIDTH-1 downto BYTE_ADDR_WIDTH ;

  constant WB_ADDR_WIDTH         : integer := CountDontCare(WB_ADDR) ; 
--  subtype  WbAddrRange is natural range WB_ADDR_WIDTH-1 downto BYTE_ADDR_WIDTH ;
--  constant REGISTER_ADDR_WIDTH   : integer := CountDontCare(REGISTER_ADDR) ; 
--  subtype  RegisterAddrRange is natural range REGISTER_ADDR_WIDTH-1 downto BYTE_ADDR_WIDTH ;
--  constant MEMORY_ADDR_WIDTH     : integer := CountDontCare(MEMORY_ADDR) ;
--  subtype  MemoryAddrRange   is natural range MEMORY_ADDR_WIDTH-1 downto BYTE_ADDR_WIDTH ; 

end WishboneRegisterSubordinate;

architecture VerificationComponent of WishboneRegisterSubordinate is
  -- Items Handled by Directives
  signal ModelID               : AlertLogIDType ;
  signal UseCoverageDelays     : boolean := FALSE ; 
  signal ArrDelayCovID         : DelayCoverageIDArrayType(1 to 1) ;
  alias  DelayCovID            is ArrDelayCovID(1) ;
  constant DEFAULT_BURST_MODE  : AddressBusFifoBurstModeType := ADDRESS_BUS_BURST_WORD_MODE ;
  signal BurstFifoMode         : AddressBusFifoBurstModeType := DEFAULT_BURST_MODE ;
  signal TransactionDone       : boolean := TRUE ; 
  signal WriteTransactionDone  : boolean := TRUE ; 
  signal ReadTransactionDone   : boolean := TRUE ; 
  signal WriteTransactionCount : integer := 0 ; 
  signal ReadTransactionCount  : integer := 0 ;  
  
  -- Configuration Items
  signal DelayValueSetting : integer := 0 ; 

  -- Internal Resources
  signal Params     : ModelParametersIDType ;
  signal MemoryID   : MemoryIDType ; 
  signal DmaFifo    : osvvm.ScoreboardPkg_slv.ScoreboardIDType ;

  -- Functional signals
  signal Enable   : std_logic ;
  signal WrAck    : std_logic ;
  signal RdAck    : std_logic ;

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
    variable ID, ParentID : AlertLogIDType ;
    variable vMemID  : MemoryIDType ; 
    variable vParams : ModelParametersIDType ; 
  begin
  
    ID  := NewID(MODEL_INSTANCE_NAME) ;
    ModelID   <= ID ;

    -- Select ParentID for Memory Model
    if MODEL_INSTANCE_NAME /= LOCAL_MEMORY_NAME then 
      -- No Match:  Memory Model is a child of this ID 
      ParentID := ID ; 
    else
      -- Match: Memory Data Structure uses same AlertLogID as VC
      ParentID := ALERTLOG_BASE_ID ; 
    end if ; 
    
    vMemID := NewID(
      Name       => LOCAL_MEMORY_NAME, 
      AddrWidth  => WB_ADDR_WIDTH,      -- Address for registers and memory
      DataWidth  => DATA_WIDTH,         -- Word oriented
      ParentID   => ParentID, 
      Search     => NAME
    ) ; 
    MemoryID  <= vMemID ; 

--    vParams    := NewID("Wishbone Parameters", to_integer(OPTIONS_MARKER), ID) ; 
--    InitAxiOptions(vParams) ;
--    Params     <= vParams ; 

    -- FIFOs get an AlertLogID with NewID, however, it does not print in ReportAlerts (due to DoNotReport)
    --   FIFOS only generate usage type errors 
    DmaFifo   <= NewID("DmaFifo", ID, ReportMode => DISABLED, Search => PRIVATE_NAME);
    wait ;
  end process Initialize ;

  ------------------------------------------------------------
  --  Transaction Dispatcher
  --    Dispatches transactions to
  ------------------------------------------------------------
  TransactionDispatcher : process
    variable Local  : WishboneBus'subtype ; 
    alias LocalAdr  : std_logic_vector(Local.Adr'length-1 downto 0) is Local.Adr ; 
    alias LocalByteAdr is LocalAdr(BYTE_ADDR_WIDTH -1 downto 0) ;

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
          DoDirectiveTransactions (
            TransRec              => TransRec             ,
            Clk                   => Clk                  ,
            ModelID               => ModelID              ,
            UseCoverageDelays     => UseCoverageDelays    ,
            DelayCovID            => ArrDelayCovID        ,
            -- Below currently unused
            BurstFifoMode         => BurstFifoMode        ,
            TransactionDone       => TransactionDone      ,
            WriteTransactionDone  => WriteTransactionDone ,
            ReadTransactionDone   => ReadTransactionDone  ,
            WriteTransactionCount => WriteTransactionCount,
            ReadTransactionCount  => ReadTransactionCount
          ) ;


      end case ;
    end loop DispatchLoop ;
  end process TransactionDispatcher ;

  ------------------------------------------------------------
  -- Decode and Combine 
  ------------------------------------------------------------
  Enable            <= WishboneBus.Adr ?= NORM_WB_ADDR ;
  WishboneBus.Ack   <= WrAck or RdAck after tpd_Clk_Ack ; 
  WishboneBus.Rty   <= '0' ; 
  WishboneBus.Err   <= '0' ; 
  WishboneBus.Stall <= WishboneBus.Stb and not (WrAck or RdAck) after tpd_Clk_Stall ; 
 
  ------------------------------------------------------------
  -- Write to Register Bank
  ------------------------------------------------------------
  WriteProc : process 
    variable Offset : integer ; 
    variable DelayCycles : integer ; 
    variable WData : WishboneDataBusType ; 
--    variable WData : WishboneBus.iDat'Subtype ; -- breaks ActiveHDL
  begin
    WrAck <= '0' ; 
    WriteLoop : loop 
      wait until rising_edge(Clk) and Enable = '1' and WishboneBus.Stb = '1' and WishboneBus.We = '1' ; 
      if    NormalizedAddr ?= NORM_DMA_WRITE_ADDR then 
        --  accepts full word writes
        push(DmaFifo, NormalizediDat) ;

      elsif NormalizedAddr ?= NORM_REGISTER_ADDR then 
        MemRead(MemoryID, NormalizedAddr(WordAddrRange), WData) ;
        for i in 0 to SEL_WIDTH-1 loop 
          if WishboneBus.Sel(i) = '1' then 
            Offset := i * 8 ; 
            WData(Offset + 7 downto Offset) := NormalizediDat(Offset + 7 downto Offset) ; 
          end if ; 
        end loop ;
        MemWrite(MemoryID, NormalizedAddr(WordAddrRange), WData) ;
      
      elsif NormalizedAddr ?= NORM_MEMORY_ADDR then
        MemRead(MemoryID, NormalizedAddr(WordAddrRange), WData) ;
        for i in 0 to SEL_WIDTH-1 loop 
          if WishboneBus.Sel(i) = '1' then 
            Offset := i * 8 ; 
            WData(Offset + 7 downto Offset) := NormalizediDat(Offset + 7 downto Offset) ; 
          end if ; 
        end loop ;
        MemWrite(MemoryID, NormalizedAddr(WordAddrRange), WData) ;

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
    variable DelayCycles : integer ; 
    variable RData : WishboneDataBusType ; 
--    variable RData : WishboneBus.oDat'Subtype ; -- breaks ActiveHDL
begin
    RdAck <= '0' ; 
    ReadLoop : loop 
      wait until rising_edge(Clk) and Enable = '1' and WishboneBus.Stb = '1' and WishboneBus.We = '0' ;
      if    NormalizedAddr ?= NORM_DMA_READ_ADDR then 
        --  accepts full word writes
        RData := pop(DmaFifo) ;

      elsif NormalizedAddr ?= NORM_REGISTER_ADDR then 
        MemRead(MemoryID, NormalizedAddr(WordAddrRange), RData) ;
      
      elsif NormalizedAddr ?= NORM_MEMORY_ADDR then
        MemRead(MemoryID, NormalizedAddr(WordAddrRange), RData) ;

      end if ; 

      DelayCycles := GetRandDelay(DelayCovID) when UseCoverageDelays else DelayValueSetting ; 
      WaitForClock(Clk, DelayCycles) ; 
      RdAck <= '1' ; 
      WishboneBus.oDat <= RData ;

      WaitForClock(Clk) ;
      RdAck <= '0' ; 
    end loop ReadLoop ; 
  end process ReadProc ;
end VerificationComponent ;
