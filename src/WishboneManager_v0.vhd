--
--  File Name:         WishboneManager.vhd
--  Design Unit Name:  WishboneManager
--  Revision:          OSVVM MODELS STANDARD VERSION
--
--  Maintainer:        Jim Lewis      email:  jim@synthworks.com
--  Contributor(s):
--     Jim Lewis      jim@synthworks.com
--
--
--  Description:
--      Wishbone Manager Model
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

entity WishboneManager is
generic (
  MODEL_ID_NAME    : string := "" ;
  tperiod_Clk      : time   := 10 ns ;
  
  DEFAULT_DELAY    : time   := 1 ns  

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

  -- Derive AXI interface properties from the AxiBus
  constant WISHBONE_ADDR_WIDTH      : integer := WishboneBus.Adr'length ;
  constant WISHBONE_DATA_WIDTH      : integer := WishboneBus.iDat'length ;
  
  -- Derive ModelInstance label from path_name
  constant MODEL_INSTANCE_NAME : string :=
    -- use MODEL_ID_NAME Generic if set, otherwise use instance label (preferred if set as entityname_1)
    IfElse(MODEL_ID_NAME /= "", MODEL_ID_NAME, to_lower(PathTail(WishboneManager'PATH_NAME))) ;

  constant MODEL_NAME : string := "WishboneManager" ;
  
end entity WishboneManager ;
architecture VerificationComponent of WishboneManager is

  signal ModelID, ProtocolID, DataCheckID, BusFailedID : AlertLogIDType ;
  signal WriteDelayCov, ReadDelayCov : DelayCoverageIDType ;

  constant DATA_BYTE_WIDTH : integer := WISHBONE_DATA_WIDTH / 8 ;
  constant BYTE_ADDR_WIDTH : integer := integer(ceil(log2(real(DATA_BYTE_WIDTH)))) ;
  constant SEL_WIDTH       : integer := WISHBONE_DATA_WIDTH/8 ;
  
  signal Params : ModelParametersIDType ;

  -- Internal Resources
  signal AddressFifo                 : osvvm.ScoreboardPkg_slv.ScoreboardIDType ;
  signal ReadDataFifo                : osvvm.ScoreboardPkg_slv.ScoreboardIDType ;

  signal AddressRequestCount,  AddressDoneCount        : integer := 0 ;
  signal ReadDataExpectCount,  ReadDataReceiveCount     : integer := 0 ;


  constant DEFAULT_BURST_MODE : AddressBusFifoBurstModeType := ADDRESS_BUS_BURST_WORD_MODE ;
  signal   BurstFifoMode      : AddressBusFifoBurstModeType := DEFAULT_BURST_MODE ;
  signal   BurstFifoByteMode  : boolean := (DEFAULT_BURST_MODE = ADDRESS_BUS_BURST_BYTE_MODE) ; 
  
begin

  ------------------------------------------------------------
  -- Turn off drivers not being driven by this model
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
    ID                      := NewID(MODEL_INSTANCE_NAME) ;
    ModelID                 <= ID ;
    ProtocolID              <= NewID("Protocol Error", ID ) ;
    DataCheckID             <= NewID("Data Check", ID ) ;
    BusFailedID             <= NewID("No response", ID ) ;
    
    vParams                 := NewID("Wishbone Parameters", to_integer(OPTIONS_MARKER), ID) ; 
    InitAxiOptions(vParams) ;
    Params                  <= vParams ; 

    WriteResponseScoreboard <= NewID("WriteResp SB", ID, Search => PRIVATE_NAME);
    ReadResponseScoreboard  <= NewID("ReadResp SB",  ID, Search => PRIVATE_NAME);

    -- FIFOs get an AlertLogID with NewID, however, it does not print in ReportAlerts (due to DoNotReport)
    --   FIFOS only generate usage type errors 
    AddressFifo             <= NewID("AddressFifo",     ID, ReportMode => DISABLED, Search => PRIVATE_NAME);
    ReadDataFifo            <= NewID("ReadDataFifo",      ID, ReportMode => DISABLED, Search => PRIVATE_NAME);

    wait ;
  end process Initialize ;


  ------------------------------------------------------------
  --  Transaction Dispatcher
  --    Dispatches transactions to
  ------------------------------------------------------------
  TransactionDispatcher : process
    variable ReadDataTransactionCount : integer := 1 ;
    variable ByteCount          : integer ;
    variable TransfersInBurst   : integer ;

    variable WishboneOption    : WishboneOptionsType ;
    variable WishboneOptionVal : integer ;

    variable AxiDefaults    : AxiBus'subtype ;

    
    variable WriteByteAddr   : integer ;

    variable BytesToSend              : integer ;
    variable BytesPerTransfer         : integer ;
    variable MaxBytesInFirstTransfer  : integer ;

    variable BytesInTransfer : integer ;
    variable BytesToReceive  : integer ;
    variable DataBitOffset   : integer ;

    variable ReadByteAddr    : integer ;
    variable ReadProt        : WishboneProtType ;

    variable ExpectedData    : std_logic_vector(LRD.Data'range) ;

    variable Operation       : AddressBusOperationType ;
    variable WriteDataCount   : integer := 0 ;
  begin
    AxiDefaults := InitWishboneRec(AxiDefaults, '0') ;
    LAW.Size    := to_slv(AXI_BYTE_ADDR_WIDTH, LAW.Size'length) ;
    LAW.Burst   := "01" ;  -- INCR
    LWR.Resp    := to_WishboneRespType(OKAY);
    LAR.Size    := to_slv(AXI_BYTE_ADDR_WIDTH, LAR.Size'length) ;
    LAR.Burst   := "01" ;  -- INCR
    LRD.Resp    := to_WishboneRespType(OKAY) ;
    
    wait for 0 ns ; -- Allow ModelID to become valid
    TransRec.Params         <= Params ; 
    TransRec.WriteBurstFifo <= NewID("WriteBurstFifo",      ModelID, Search => PRIVATE_NAME) ;
    TransRec.ReadBurstFifo  <= NewID("ReadBurstFifo",       ModelID, Search => PRIVATE_NAME) ;
    WriteAddressDelayCov    <= NewID("WriteAddrDelayCov",   ModelID, ReportMode => DISABLED) ; 
    WriteDataDelayCov       <= NewID("WriteDataDelayCov",   ModelID, ReportMode => DISABLED) ; 
    WriteResponseDelayCov   <= NewID("WriteRespDelayCov",   ModelID, ReportMode => DISABLED) ; 
    ReadAddressDelayCov     <= NewID("ReadAddrDelayCov",    ModelID, ReportMode => DISABLED) ; 
    ReadDataDelayCov        <= NewID("ReadDataDelayCov",    ModelID, ReportMode => DISABLED) ; 
    
--!! AWCache, ARCache Defaults
    DispatchLoop : loop
      WaitForTransaction(
         Clk      => Clk,
         Rdy      => TransRec.Rdy,
         Ack      => TransRec.Ack
      ) ;
      Operation := TransRec.Operation ;

      case Operation is
        -- Execute Standard Directive Transactions
        when WAIT_FOR_TRANSACTION =>
          -- Waits for All WRITE and READ Transactions to complete
          if WriteAddressRequestCount /= WriteAddressDoneCount then
            -- Block until both write address done.
            wait until WriteAddressRequestCount = WriteAddressDoneCount ;
          end if ;
          if WriteDataRequestCount /= WriteDataDoneCount then
            -- Block until both write data done.
            wait until WriteDataRequestCount = WriteDataDoneCount ;
          end if ;
          if WriteResponseExpectCount /= WriteResponseReceiveCount then
            -- Block until both write response done.
            wait until WriteResponseExpectCount = WriteResponseReceiveCount ;
          end if ;

          if ReadAddressRequestCount /= ReadAddressDoneCount then
            -- Block until both read address done.
            wait until ReadAddressRequestCount = ReadAddressDoneCount ;
          end if ;
          if ReadDataExpectCount /= ReadDataReceiveCount then
            -- Block until both read data done.
            wait until ReadDataExpectCount = ReadDataReceiveCount ;
          end if ;

        when WAIT_FOR_WRITE_TRANSACTION =>
          if WriteAddressRequestCount /= WriteAddressDoneCount then
            -- Block until both write address done.
            wait until WriteAddressRequestCount = WriteAddressDoneCount ;
          end if ;
          if WriteDataRequestCount /= WriteDataDoneCount then
            -- Block until both write data done.
            wait until WriteDataRequestCount = WriteDataDoneCount ;
          end if ;
          if WriteResponseExpectCount /= WriteResponseReceiveCount then
            -- Block until both write response done.
            wait until WriteResponseExpectCount = WriteResponseReceiveCount ;
          end if ;
          wait for 0 ns ; 

        when WAIT_FOR_READ_TRANSACTION =>
          if ReadAddressRequestCount /= ReadAddressDoneCount then
            -- Block until both read address done.
            wait until ReadAddressRequestCount = ReadAddressDoneCount ;
          end if ;
          if ReadDataExpectCount /= ReadDataReceiveCount then
            -- Block until both read data done.
            wait until ReadDataExpectCount = ReadDataReceiveCount ;
          end if ;
          wait for 0 ns ; 

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
          case TransRec.Options is
            when WRITE_ADDRESS_ID  =>  WriteAddressDelayCov  <= GetDelayCoverage(TransRec.IntToModel) ;
            when WRITE_DATA_ID     =>  WriteDataDelayCov     <= GetDelayCoverage(TransRec.IntToModel) ;
            when WRITE_RESPONSE_ID =>  WriteResponseDelayCov <= GetDelayCoverage(TransRec.IntToModel) ;
            when READ_ADDRESS_ID   =>  ReadAddressDelayCov   <= GetDelayCoverage(TransRec.IntToModel) ;
            when READ_DATA_ID      =>  ReadDataDelayCov      <= GetDelayCoverage(TransRec.IntToModel) ;
            when others =>  Alert(ModelID, "SetDelayCoverageID, Invalid ID requested = " & to_string(TransRec.IntToModel), FAILURE) ;  
          end case ; 
          UseCoverageDelays <= TRUE ; 

        when GET_DELAYCOV_ID =>
          case TransRec.Options is
            when WRITE_ADDRESS_ID  =>  TransRec.IntFromModel <= WriteAddressDelayCov.ID  ;
            when WRITE_DATA_ID     =>  TransRec.IntFromModel <= WriteDataDelayCov.ID     ;
            when WRITE_RESPONSE_ID =>  TransRec.IntFromModel <= WriteResponseDelayCov.ID ;
            when READ_ADDRESS_ID   =>  TransRec.IntFromModel <= ReadAddressDelayCov.ID   ;
            when READ_DATA_ID      =>  TransRec.IntFromModel <= ReadDataDelayCov.ID      ;
            when others =>  Alert(ModelID, "GetDelayCoverageID, Invalid ID requested = " & to_string(TransRec.IntToModel), FAILURE) ;  
          end case ; 
          UseCoverageDelays <= TRUE ; 

        when SET_BURST_MODE =>                      
          BurstFifoMode       <= TransRec.IntToModel ;
          BurstFifoByteMode   <= (TransRec.IntToModel = ADDRESS_BUS_BURST_BYTE_MODE) ;
          wait for 0 ns ; 
          AlertIf(ModelID, not IsAddressBusBurstMode(BurstFifoMode), 
            "Invalid Burst Mode " & to_string(BurstFifoMode), FAILURE) ;
              
        when GET_BURST_MODE =>                      
          TransRec.IntFromModel <= BurstFifoMode ;

        when GET_TRANSACTION_COUNT =>
          TransRec.IntFromModel <= integer(TransRec.Rdy) ; --  WriteAddressDoneCount + ReadAddressDoneCount ;
          wait for 0 ns ; 

        when GET_WRITE_TRANSACTION_COUNT =>
          TransRec.IntFromModel <= WriteAddressDoneCount ;
          wait for 0 ns ; 

        when GET_READ_TRANSACTION_COUNT =>
          TransRec.IntFromModel <= ReadAddressDoneCount ;
          wait for 0 ns ; 

        -- Model Transaction Dispatch
        when WRITE_OP | WRITE_ADDRESS | WRITE_DATA | ASYNC_WRITE | ASYNC_WRITE_ADDRESS | ASYNC_WRITE_DATA =>
          -- For All Write Operations - Write Address and Write Data
          LAW.Addr  := SafeResize(ModelID, TransRec.Address, LAW.Addr'length) ;
          WriteByteAddr := CalculateByteAddress(LAW.Addr, AXI_BYTE_ADDR_WIDTH) ;

          if IsWriteAddress(Operation) then
            -- AlertIf(ModelID, TransRec.AddrWidth /= AXI_ADDR_WIDTH, "Write Address length does not match", FAILURE) ;

            LAW.Len := (others => '0') ;

            -- Initiate Write Address
            Push(WriteAddressFifo, LAW.Addr  & LAW.Len & LAW.Prot & LAW.ID & LAW.Size & LAW.Burst & LAW.Lock & LAW.Cache & LAW.QOS & LAW.Region & LAW.User) ;
            Increment(WriteAddressRequestCount) ;
          end if ;

          if IsWriteData(Operation) then
            -- Single Transfer Write Data Handling
            CheckDataIsBytes(ModelID, TransRec.DataWidth, "Manager Write: ", WriteDataRequestCount+1) ;
            CheckDataWidth  (ModelID, TransRec.DataWidth, WriteByteAddr, AXI_DATA_WIDTH, "Manager Write: ", WriteDataRequestCount+1) ;
            LWD.Data  := AlignBytesToDataBus(SafeResize(ModelID, TransRec.DataToModel, LWD.Data'length), TransRec.DataWidth, WriteByteAddr) ;
--            LWD.Strb  := CalculateWriteStrobe(LWD.Data) ;
--            Push(WriteDataFifo, '0' & '1' & LWD.Data & LWD.Strb & LWD.User & LWD.ID) ;
            Push(WriteDataFifo, '0' & '1' & LWD.Data & LWD.User & LWD.ID) ;

            Increment(WriteDataRequestCount) ;
            WriteDataCount := WriteDataCount + 1 ; 
          end if ;
          
          -- Allow RequestCounts to update
          wait for 0 ns ;  

--!! If burst emulation is added, then this will need to be a while loop since
--!! more than one transaction will be dispatched at a time.
          if WriteAddressRequestCount /= WriteResponseExpectCount and
             WriteDataCount           /= WriteResponseExpectCount 
          then
            -- Queue Expected Write Response
            Push(WriteResponseScoreboard, LWR.Resp) ;
            Increment(WriteResponseExpectCount) ;
          end if ;
          
          if IsBlockOnWriteAddress(Operation) and
              WriteAddressRequestCount /= WriteAddressDoneCount then
            -- Block until both write address done.
            wait until WriteAddressRequestCount = WriteAddressDoneCount ;
          end if ;
          if IsBlockOnWriteData(Operation) and
              WriteDataRequestCount /= WriteDataDoneCount then
            -- Block until both write data done.
            wait until WriteDataRequestCount = WriteDataDoneCount ;
          end if ;


        -- Model Transaction Dispatch
        when WRITE_BURST | ASYNC_WRITE_BURST =>
          LAW.Addr  := SafeResize(ModelID, TransRec.Address, LAW.Addr'length) ;
          WriteByteAddr := CalculateByteAddress(LAW.Addr, AXI_BYTE_ADDR_WIDTH);
          BytesPerTransfer := AXI_DATA_BYTE_WIDTH ;
--!!          BytesPerTransfer := 2**to_integer(LAW.Size);
--            AlertIf(ModelID, BytesPerTransfer /= AXI_DATA_BYTE_WIDTH,
--              "Write Bytes Per Transfer (" & to_string(BytesPerTransfer) & ") " &
--              "/= AXI_DATA_BYTE_WIDTH (" & to_string(AXI_DATA_BYTE_WIDTH) & ")"
--            );

          if IsWriteAddress(Operation) then
            -- Write Address Handling
--            AlertIf(ModelID, TransRec.AddrWidth /= AXI_ADDR_WIDTH, "Write Address length does not match", FAILURE) ;

            -- Burst transfer, calculate burst length
            if BurstFifoByteMode then 
              LAW.Len := to_slv(CalculateBurstLen(TransRec.DataWidth, WriteByteAddr, BytesPerTransfer), LAW.Len'length) ;
            else 
              LAW.Len := to_slv(TransRec.DataWidth-1, LAW.Len'length) ;
            end if ;
            
            -- Initiate Write Address
            Push(WriteAddressFifo, LAW.Addr  & LAW.Len & LAW.Prot & LAW.ID & LAW.Size & LAW.Burst & LAW.Lock & LAW.Cache & LAW.QOS & LAW.Region & LAW.User) ;

            Increment(WriteAddressRequestCount) ;
          end if ;

          if IsWriteData(Operation) then
            if BurstFifoByteMode then 
              BytesToSend       := TransRec.DataWidth ;
              TransfersInBurst  := 1 + CalculateBurstLen(BytesToSend, WriteByteAddr, BytesPerTransfer) ;
            else
              TransfersInBurst := TransRec.DataWidth ;
            end if ; 
            
--            PopWriteBurstData(TransRec.WriteBurstFifo, BurstFifoMode, LWD.Data, LWD.Strb, BytesToSend, WriteByteAddr) ;
            PopWriteBurstData(TransRec.WriteBurstFifo, BurstFifoMode, LWD.Data, BytesToSend, WriteByteAddr) ;

            for BurstLoop in TransfersInBurst downto 2 loop    
 --!!              Push(WriteDataFifo, '1' & '0' & LWD.Data & LWD.Strb & LWD.User & LWD.ID) ;
             Push(WriteDataFifo, '1' & '0' & LWD.Data & LWD.User & LWD.ID) ;
--!!              PopWriteBurstData(TransRec.WriteBurstFifo, BurstFifoMode, LWD.Data, LWD.Strb, BytesToSend, 0) ;
              PopWriteBurstData(TransRec.WriteBurstFifo, BurstFifoMode, LWD.Data, BytesToSend, 0) ;
            end loop ; 
            
            -- Special handle last push
--!!            Push(WriteDataFifo, '1' & '1' & LWD.Data & LWD.Strb & LWD.User & LWD.ID) ;
            Push(WriteDataFifo, '1' & '1' & LWD.Data & LWD.User & LWD.ID) ;

            -- Increment(WriteDataRequestCount) ;
            WriteDataRequestCount        <= Increment(WriteDataRequestCount, TransfersInBurst) ;
            WriteDataCount := WriteDataCount + 1 ; 
          end if ;

          -- Allow RequestCounts to update
          wait for 0 ns ;  

--!! will need to be a while loop if more than one transaction can be dispatched at a time.
--!! only happens if bursts are emulated - ie translated from a burst cycle to a multiple individual cycles
          if WriteAddressRequestCount /= WriteResponseExpectCount and 
             WriteDataCount           /= WriteResponseExpectCount 
          then
            -- Queue Expected Write Response
            Push(WriteResponseScoreboard, LWR.Resp) ;
            Increment(WriteResponseExpectCount) ;
          end if ;

          if IsBlockOnWriteAddress(Operation) and
              WriteAddressRequestCount /= WriteAddressDoneCount then
            -- Block until write address done.
            wait until WriteAddressRequestCount = WriteAddressDoneCount ;
          end if ;
          if IsBlockOnWriteData(Operation) and
              WriteDataRequestCount /= WriteDataDoneCount then
            -- Block until write data done.
            wait until WriteDataRequestCount = WriteDataDoneCount ;
          end if ;

        when READ_OP | READ_CHECK | READ_ADDRESS | READ_DATA | READ_DATA_CHECK | ASYNC_READ_ADDRESS | ASYNC_READ_DATA | ASYNC_READ_DATA_CHECK =>
          if IsReadAddress(Operation) then
            -- Send Read Address to Read Address Handler and Read Data Handler
            LAR.Addr   :=  SafeResize(ModelID, TransRec.Address, LAR.Addr'length) ;
            ReadByteAddr  :=  CalculateByteAddress(LAR.Addr, AXI_BYTE_ADDR_WIDTH);
--             AlertIf(ModelID, TransRec.AddrWidth /= AXI_ADDR_WIDTH, "Read Address length does not match", FAILURE) ;
            BytesPerTransfer := 2**to_integer(LAR.Size);

            LAR.Len := (others => '0') ;

            Push(ReadAddressFifo, LAR.Addr & LAR.Len & LAR.Prot & LAR.ID & LAR.Size & LAR.Burst & LAR.Lock & LAR.Cache & LAR.QOS & LAR.Region & LAR.User) ;
            Push(ReadAddressTransactionFifo, LAR.Addr & LAR.Prot);
            Increment(ReadAddressRequestCount) ;

            -- Expect a Read Data Cycle
            Push(ReadResponseScoreboard, LRD.Resp) ;
            increment(ReadDataExpectCount) ;
          end if ;
          wait for 0 ns ; 

          if IsTryReadData(Operation) and IsEmpty(ReadDataFifo) then
            -- Data not available
            -- ReadDataReceiveCount < ReadDataTransactionCount then
            TransRec.BoolFromModel <= FALSE ;
            TransRec.DataFromModel <= (TransRec.DataFromModel'range => '0') ; 
          elsif IsReadData(Operation) then
            (LAR.Addr, ReadProt) := Pop(ReadAddressTransactionFifo) ;
            ReadByteAddr  :=  CalculateByteAddress(LAR.Addr, AXI_BYTE_ADDR_WIDTH);

            -- Wait for Data Ready
            if IsEmpty(ReadDataFifo) then
              WaitForToggle(ReadDataReceiveCount) ;
            end if ;
            TransRec.BoolFromModel <= TRUE ;

            -- Get Read Data
            LRD.Data := Pop(ReadDataFifo) ;
            CheckDataIsBytes(ModelID, TransRec.DataWidth, "Manager Read: ", ReadDataExpectCount) ;
            CheckDataWidth  (ModelID, TransRec.DataWidth, ReadByteAddr, AXI_DATA_WIDTH, "Manager Read: ", ReadDataExpectCount) ;
            LRD.Data := AlignDataBusToBytes(LRD.Data, TransRec.DataWidth, ReadByteAddr) ;
--            AxiReadDataAlignCheck (ModelID, LRD.Data, TransRec.DataWidth, LAR.Addr, AXI_DATA_BYTE_WIDTH, AXI_BYTE_ADDR_WIDTH) ;
            TransRec.DataFromModel <= SafeResize(ModelID, LRD.Data, TransRec.DataFromModel'length) ;

            -- Check or Log Read Data
            if IsReadCheck(TransRec.Operation) then
              ExpectedData := SafeResize(ModelID, TransRec.DataToModel, ExpectedData'length) ;
  --!!9 TODO:  Change format to Transaction #, Address, Prot, Read Data
  --!! Run regressions before changing
              AffirmIf( DataCheckID, MetaMatch(LRD.Data, ExpectedData),
                "Read Data: " & to_hxstring(LRD.Data) &
                "  Read Address: " & to_hxstring(LAR.Addr) &
                "  Prot: " & to_hxstring(ReadProt),
                "  Expected: " & to_hxstring(ExpectedData),
                TransRec.StatusMsgOn or IsLogEnabled(ModelID, INFO) ) ;
            else
  --!!9 TODO:  Change format to Transaction #, Address, Prot, Read Data
  --!! Run regressions before changing
              Log( ModelID,
                "Read Data: " & to_hxstring(LRD.Data) &
                "  Read Address: " & to_hxstring(LAR.Addr) &
                "  Prot: " & to_hxstring(ReadProt),
                INFO,
                TransRec.StatusMsgOn
              ) ;
            end if ;
          end if ;

          -- Transaction wait time
          wait for 0 ns ;  wait for 0 ns ;

        when READ_BURST =>
          if IsReadAddress(Operation) then
            -- Send Read Address to Read Address Handler and Read Data Handler
            LAR.Addr   :=  SafeResize(ModelID, TransRec.Address, LAR.Addr'length) ;
            ReadByteAddr  :=  CalculateByteAddress(LAR.Addr, AXI_BYTE_ADDR_WIDTH);
--            AlertIf(ModelID, TransRec.AddrWidth /= AXI_ADDR_WIDTH, "Read Address length does not match", FAILURE) ;
            BytesPerTransfer := 2**to_integer(LAR.Size);

            -- Burst transfer, calculate burst length
            if BurstFifoByteMode then 
              TransfersInBurst := 1 + CalculateBurstLen(TransRec.DataWidth, ReadByteAddr, BytesPerTransfer) ;
            else 
              TransfersInBurst := TransRec.DataWidth ; 
            end if ;
            LAR.Len := to_slv(TransfersInBurst - 1, LAR.Len'length) ;

            Push(ReadAddressFifo, LAR.Addr & LAR.Len & LAR.Prot & LAR.ID & LAR.Size & LAR.Burst & LAR.Lock & LAR.Cache & LAR.QOS & LAR.Region & LAR.User) ;
            Push(ReadAddressTransactionFifo, LAR.Addr & LAR.Prot);
            Increment(ReadAddressRequestCount) ;

            -- Expect a Read Data Cycle
            for i in 1 to TransfersInBurst loop
              Push(ReadResponseScoreboard, LRD.Resp) ;
            end loop ;
  -- Should this be + TransfersInBurst ; ???
            ReadDataExpectCount <= Increment(ReadDataExpectCount, TransfersInBurst) ;
          end if ;

  --!!3 Implies that any separate ReadDataBurst or TryReadDataBurst
  --!!3 must include the transfer length and for Try
  --!!3 if ReadDataFifo has that number of transfers.
  --!!3 First Check IsReadData, then Calculate #Transfers,
  --!!3 Then if TryRead, and ReadDataFifo.FifoCount < #Transfers, then FALSE
  --!!3 Which reverses the order of the following IF statements
          if IsTryReadData(Operation) and IsEmpty(ReadDataFifo) then
            -- Data not available
            -- ReadDataReceiveCount < ReadDataTransactionCount then
            TransRec.BoolFromModel <= FALSE ;
          elsif IsReadData(Operation) then
            TransRec.BoolFromModel <= TRUE ;
            (LAR.Addr, ReadProt) := Pop(ReadAddressTransactionFifo) ;
            ReadByteAddr := CalculateByteAddress(LAR.Addr, AXI_BYTE_ADDR_WIDTH);
            BytesPerTransfer := 2**to_integer(LAR.Size);
--!!            BytesPerTransfer  := AXI_DATA_BYTE_WIDTH ;

--!!            AlertIf(ModelID, BytesPerTransfer /= AXI_DATA_BYTE_WIDTH,
--!!              "Write Bytes Per Transfer (" & to_string(BytesPerTransfer) & ") " &
--!!              "/= AXI_DATA_BYTE_WIDTH (" & to_string(AXI_DATA_BYTE_WIDTH) & ")"
--!!            );

            if BurstFifoByteMode then 
              BytesToReceive    := TransRec.DataWidth ;
              TransfersInBurst  := 1 + CalculateBurstLen(BytesToReceive, ReadByteAddr, BytesPerTransfer) ;
            else
              TransfersInBurst  := TransRec.DataWidth ;
            end if ; 

            for BurstLoop in 1 to TransfersInBurst loop
              if IsEmpty(ReadDataFifo) then
                WaitForToggle(ReadDataReceiveCount) ;
              end if ;
              LRD.Data := Pop(ReadDataFifo) ;
              
              PushReadBurstData(TransRec.ReadBurstFifo, BurstFifoMode, LRD.Data, BytesToReceive, ReadByteAddr) ;
              ReadByteAddr := 0 ;
            end loop ;
          end if ;

        -- Model Configuration Options
        when SET_MODEL_OPTIONS =>
          WishboneOption := WishboneOptionsType'val(TransRec.Options) ;
          if IsAxiInterface(WishboneOption) then
            SetWishboneInterfaceDefault(AxiDefaults, WishboneOption, TransRec.IntToModel) ;
          else
            Set(Params, TransRec.Options, TransRec.IntToModel) ;
          end if ;

        when GET_MODEL_OPTIONS =>
          WishboneOption := WishboneOptionsType'val(TransRec.Options) ;
          if IsAxiInterface(WishboneOption) then
            TransRec.IntFromModel <= GetWishboneInterfaceDefault(AxiDefaults, WishboneOption) ;
          else
            TransRec.IntFromModel <= Get(Params, TransRec.Options) ;
          end if ;

        -- The End -- Done
        when others =>
          -- Signal multiple Driver Detect or not implemented transactions.
          Alert(ModelID, ClassifyUnimplementedOperation(TransRec), FAILURE) ;

      end case ;
    end loop DispatchLoop ;
  end process TransactionDispatcher ;
  
  iAck <= WishboneBus.Ack or WishboneBus.Rty or WishboneBus.Err  ;
  
  CycleDone <=
    not WishboneBus.Stall when Mode = PIPELINED else 
    

  ------------------------------------------------------------
  --  AddressHandler
  --    Execute Write Address Transactions
  ------------------------------------------------------------
  WriteAddressHandler : process
    alias    WB    is WishboneBus ;
    variable Local : WishboneBus'subtype ;
    variable DelayCycles : integer ; 
  begin
    -- Initialize Ports
    -- Wishbone Lite Signaling
    WB.Cyc    <= '0' ;
    WB.Lock   <= '0' ;
    WB.Stb    <= '0' ;
    WB.Adr    <= (Local.Prot'range   => '0') ;
    WB.oDat   <= (Local.Prot'range   => '0') ;
    WB.Cti    <= (Local.Prot'range   => '0') ;
    
    wait for 0 ns ; -- Allow WriteAddressFifo to initialize
    wait for 0 ns ; -- Allow Cov models to initialize 
    -- Initialize DelayCoverage Models
    AddBins (AddressDelayCov.BurstLengthCov,  GenBin(2,10,1)) ;
    AddBins (AddressDelayCov.BeatDelayCov,    GenBin(0)) ;
    AddBins (AddressDelayCov.BurstDelayCov,   GenBin(2,5,1)) ;

    AddressLoop : loop
      -- Find Transaction in FIFO
      if IsEmpty(AddressFifo) then
         WaitForToggle(AddressRequestCount) ;
      end if ;
      (Local.Op, Local.Adr, Local.BurstLen) := Pop(AddressFifo) ;

      -- Valid Delay between Transfers
      if UseCoverageDelays then 
        -- BurstCoverage Delay
        DelayCycles := GetRandDelay(WriteAddressDelayCov) ; 
        WaitForClock(Clk, DelayCycles) ;
      else
        -- Constant Delay
        WaitForClock(Clk, integer'(Get(Params, to_integer(WRITE_ADDRESS_VALID_DELAY_CYCLES)))) ; 
      end if ; 

      -- Do Transaction
      WB.Adr   <= Local.Adr      after tpd_Clk_Adr  ;
      WB.Cyc   <= '1'            after tpd_clk_Cyc  ;
      WB.Stb   <= '1'            after tpd_clk_Stb  ;
      WB.Cti   <= "000"          after tpd_clk_Cti ; 
      
      if (Local.Op = WRITE) then 
        WB.We <= '1' after tpd_clk_We ;
        WB.oDat <= Data after tpd_clk_oDat ; 
      else
        WB.We <= '0' after tpd_clk_We ; 
      end if ; 
      
      wait until rising_edge(Clk) and CycleDone = '1' ;
      
      -- Transaction Finalization
      WB.Adr   <= Local.Adr + 8     after tpd_Clk_Adr  ;
      WB.Cyc   <= '0'               after tpd_clk_Cyc  ;
      WB.Stb   <= '0'               after tpd_clk_Stb  ;
      WB.Cti   <= "000"             after tpd_clk_Cti ; 
      
      Log(ModelID,
        "Write Address." &
        "  AWAddr: "  & to_hxstring(Local.Adr) &
        "  AWProt: "  & to_string(Local.Prot) &
        "  Operation# " & to_string(WriteAddressDoneCount + 1),
        INFO
      ) ;

      Increment(WriteAddressDoneCount) ;
      wait for 0 ns ;
    end loop WriteAddressLoop ;
  end process WriteAddressHandler ;



  ------------------------------------------------------------
  --  ReadDataHandler
  --    Receive Read Data Transactions
  ------------------------------------------------------------
  ReadDataHandler : process
  begin
  
    wait until  rising_edge(Clk) and WishboneBus.We = '0' and (WishboneBus.Ack or WishboneBus.Rty or WishboneBus.Err) = '1'  ;

    if WishboneBus.We = '0'  then
      AlertIf(ReadDataReceiveCount = ReadDataExpectCount, "Received Data, but not expecting") ;

      -- capture data
      push(ReadDataFifo, AxiBus.ReadData.Data) ;
      Check(ReadResponseScoreboard, AxiBus.ReadData.Resp) ;

      increment(ReadDataReceiveCount) ;
    end if ;
    wait for 0 ns ; -- Allow ReadDataReceiveCount to update
  end process ReadDataHandler ;

end architecture VerificationComponent ;
