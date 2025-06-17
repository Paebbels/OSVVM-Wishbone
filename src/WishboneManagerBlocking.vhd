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
--      Simple blocking Wishbone Manager VC
--      Serves as an example of developing a simple VC
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

entity WishboneManager is
generic (
  MODEL_ID_NAME      : string  := "" ;
  WISHBONE_PIPELINED : boolean := FALSE ;
  
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

  -- Wishbone Bus
  WishboneBus   : inout WishboneRecType ;

  -- Testbench Transaction Interface
  TransRec      : inout AddressBusRecType 
) ;
  -- Derive ModelInstance label from path_name
  constant MODEL_INSTANCE_NAME : string :=
    -- use MODEL_ID_NAME Generic if set, otherwise use instance label (preferred if set as entityname_1)
    IfElse(MODEL_ID_NAME /= "", MODEL_ID_NAME, to_lower(PathTail(WishboneManager'PATH_NAME))) ;

  constant MODEL_NAME : string := "WishboneManager" ;
  
  -- Derive AXI interface properties from the AxiBus
  constant ADDR_WIDTH      : integer := WishboneBus.Adr'length ;
  constant DATA_WIDTH      : integer := WishboneBus.iDat'length ;
  constant DATA_NUM_BYTES  : integer := DATA_WIDTH / 8 ;
  constant SEL_WIDTH       : integer := WishboneBus.Sel'length ;
  constant BYTE_ADDR_WIDTH : integer := integer(ceil(log2(real(DATA_NUM_BYTES)))) ;
  constant BYTE_ADDR_MASK  : std_logic_vector(ADDR_WIDTH-1 downto 0) := (ADDR_WIDTH-1 downto BYTE_ADDR_WIDTH => '0') & ( BYTE_ADDR_WIDTH downto 1 => '1') ; 
  subtype  ByteAddrRange is natural range BYTE_ADDR_WIDTH-1 downto 0 ;
  alias    WB    is WishboneBus ;

end entity WishboneManager ;
architecture VerificationComponent of WishboneManager is

  -- Items Handled by Directives
  signal ModelID, ReadID, WriteID  : AlertLogIDType ;
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
  signal StaticDelayCycles : integer := 0 ; 
  signal BurstCti          : std_logic_vector(2 downto 0) := WB_CTI_INC ;
  signal Lock              : std_logic := '0' ; 
  signal PipeMode          : boolean := WISHBONE_PIPELINED ; 

  signal Params : ModelParametersIDType ;

  -- Internal Resources
  signal StartTransactionFifo        : osvvm.ScoreboardPkg_slv.ScoreboardIDType ;
  signal ReadAddressTransactionFifo  : osvvm.ScoreboardPkg_slv.ScoreboardIDType ;
  signal ReadDataFifo                : osvvm.ScoreboardPkg_slv.ScoreboardIDType ;
  signal EndTransactionFifo          : osvvm.ScoreboardPkg_slv.ScoreboardIDType ;

  signal Burst   : std_logic := '0' ;

  signal StartRequestCount, StartDoneCount  : integer := 0 ;
  signal ReadDataExpectCount,  ReadDataReceiveCount     : integer := 0 ;
  signal TransactionStartCount, TransactionDoneCount  : integer := 0 ;

  signal iAck, CycleDone : std_logic ; -- Or of Wb.Ack, Wb.Rty, Wb.
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
    ReadID                  <= NewID("Read", ID ) ;
    WriteID                 <= NewID("Write", ID, ReportMode => DISABLED ) ;
    
--    vParams                 := NewID("Wishbone Parameters", to_integer(OPTIONS_MARKER), ID) ; 
--    InitAxiOptions(vParams) ;
--    Params                  <= vParams ; 

    -- FIFOs get an AlertLogID with NewID, however, it does not print in ReportAlerts (due to DoNotReport)
    --   FIFOS only generate usage type errors 
--    StartTransactionFifo             <= NewID("StartTransactionFifo",          ID, ReportMode => DISABLED, Search => PRIVATE_NAME);
--    ReadAddressTransactionFifo       <= NewID("ReadAddressTransactionFifo",    ID, ReportMode => DISABLED, Search => PRIVATE_NAME);
--    ReadDataFifo                     <= NewID("ReadDataFifo",                  ID, ReportMode => DISABLED, Search => PRIVATE_NAME);
--    EndTransactionFifo               <= NewID("StartTransactionFifo",          ID, ReportMode => DISABLED, Search => PRIVATE_NAME);

    wait ;
  end process Initialize ;

  ------------------------------------------------------------
  --  Transaction Dispatcher
  --    Dispatches transactions to
  ------------------------------------------------------------
  TransactionDispatcher : process
    variable Local     : WishboneBus'subtype ; 
    alias    aLocalAdr : std_logic_vector(Local.Adr'length-1 downto 0) is Local.Adr ; 
    variable ByteAddr  : integer ;

    variable Operation       : AddressBusOperationType ;
    variable DelayCycles     : integer ; 
  begin
    Local := InitWishboneRec (Local, '0') ;
    -- Initialize Ports
    -- Wishbone Lite Signaling
    -- WB.Cyc    <= '0' ;  -- set by separate process
    WB.Lock   <= '0' ;
    WB.Stb    <= '0' ;
    WB.Cyc    <= '0' ;
    WB.We     <= '0' ;
    WB.Adr    <= (Local.Adr'range   => '0') ;
    WB.oDat   <= (Local.oDat'range  => '0') ;
    WB.Cti    <= (Local.Cti'range   => '0') ;
    -- PreviousWe := '1' ; 
  
    wait for 0 ns ; -- Allow ModelID to become valid
    DelayCovID   <= NewID("DelayCov",  ModelID, ReportMode => DISABLED) ; 
    wait for 0 ns ; -- Allow Cov models to initialize 
    -- Initialize DelayCoverage Models
    AddBins (DelayCovID.BurstLengthCov,  GenBin(2,10,1)) ;
    AddBins (DelayCovID.BeatDelayCov,    GenBin(0)) ;
    AddBins (DelayCovID.BurstDelayCov,   GenBin(2,5,1)) ;
  
    DispatchLoop : loop
      WaitForTransaction(
         Clk      => Clk,
         Rdy      => TransRec.Rdy,
         Ack      => TransRec.Ack
      ) ;

      -- Get Operation, Addr and Data from Record
      Operation := TransRec.Operation ;
      aLocalAdr  := SafeResize(ModelID, TransRec.Address, aLocalAdr'length) ;
      ByteAddr   := 0 when BYTE_ADDR_WIDTH = 0 else to_integer(aLocalAdr(ByteAddrRange)) ;
      Local.oDat := SafeResize(ModelID, TransRec.DataToModel, Local.oDat'length) ;

      case Operation is
        -- Model Transaction Dispatch
        when WRITE_OP | ASYNC_WRITE =>
          CheckDataWidth (WriteID, TransRec, ByteAddr, DATA_WIDTH) ;
          Local.oDat  := AlignBytesToDataBus(Local.oDat, TransRec.DataWidth, ByteAddr) ;

          DelayCycles := GetRandDelay(DelayCovID) when UseCoverageDelays else StaticDelayCycles ; 
          WaitForClock(Clk, DelayCycles) ; 

          -- Do Transaction
          TransactionStartCount <= TransactionStartCount + 1 ;
          WB.Adr   <= Local.Adr      after tpd_Clk_Adr  ;
          WB.Stb   <= '1'            after tpd_clk_Stb  ;
          WB.Cyc   <= '1'            after tpd_clk_Cyc  ;
          WB.We    <= '1'            after tpd_clk_We ;
          WB.Sel   <= CalculateWriteStrobe(Local.oDat) after tpd_Clk_Sel ; 
          WB.oDat  <= Local.oDat     after tpd_clk_oDat ; 
      
          wait until rising_edge(Clk) and iAck = '1' ;
      
          -- Transaction Finalization
          WB.Adr   <= Local.Adr + 8  after tpd_Clk_Adr  ;
          WB.Stb   <= '0'            after tpd_clk_Stb  ;
          WB.Cyc   <= '0'            after tpd_clk_Cyc  ;

          Log(WriteID,
            "Address: "      & to_hxstring(Local.Adr) &
            "  Data: "       & to_hxstring(Local.oDat) &
            "  Operation # " & to_string(TransRec.Rdy),
            INFO
          ) ;
          Increment(WriteTransactionCount) ;

        when READ_OP | READ_CHECK =>
          CheckDataWidth (ReadID, TransRec, ByteAddr, DATA_WIDTH) ;

          DelayCycles := GetRandDelay(DelayCovID) when UseCoverageDelays else StaticDelayCycles ; 
          WaitForClock(Clk, DelayCycles) ; 
  
            -- Do Transaction
--          TransactionStartCount <= TransactionStartCount + 1 ;
          WB.Adr   <= Local.Adr      after tpd_Clk_Adr  ;
          WB.Stb   <= '1'            after tpd_clk_Stb  ;
          WB.Cyc   <= '1'            after tpd_clk_Cyc  ;
          WB.We    <= '0'            after tpd_clk_We ;
          WB.Sel   <= CalculateWriteStrobe(ByteAddr, TransRec.DataWidth/8, DATA_NUM_BYTES) after tpd_Clk_Sel ; 

          wait until rising_edge(Clk) and iAck = '1' ;

          -- Transaction Finalization
          WB.Adr   <= Local.Adr + 8  after tpd_Clk_Adr  ;
          WB.Stb   <= '0'            after tpd_clk_Stb  ;
          WB.Cyc   <= '0'            after tpd_clk_Cyc  ;
      
          -- Get Read Data
          Local.iDat := AlignDataBusToBytes(WB.iDat, TransRec.DataWidth, ByteAddr) ;
          TransRec.DataFromModel <= SafeResize(ReadID, Local.iDat, TransRec.DataFromModel'length) ;

          -- Check or Log Read Data
          if IsReadCheck(Operation) then
            AffirmIfEqual( ReadID, Local.iDat, Local.oDat,
              "Address:  " & to_hxstring(Local.Adr) &
              "  Data: ",
              TransRec.StatusMsgOn or IsLogEnabled(ReadID, INFO) ) ;
          else
            Log( ReadID,
              "Address:  " & to_hxstring(Local.Adr) &
              "  Data: "   & to_hxstring(Local.iDat),
              INFO,
              TransRec.StatusMsgOn
            ) ;
          end if ;
          Increment(ReadTransactionCount) ;

        -- Model Configuration Options
        when SET_MODEL_OPTIONS =>
          case TransRec.Options is 
            when WB_CTI      =>   BurstCti          <= to_slv(TransRec.IntToModel, BurstCti'length) ;
            when WB_LOCK     =>   Lock              <= '0' when TransRec.IntToModel = 0 else '1' ;
            when WB_DELAY    =>   StaticDelayCycles <= TransRec.IntToModel ; 
            when WB_PIPELINE =>   PipeMode          <= TransRec.BoolToModel ; 
            when others      =>   Alert(ModelID, ClassifyUnimplementedOperation(TransRec) & " Option: " & to_string(TransRec.Options), FAILURE) ; 
          end case ; 

        when GET_MODEL_OPTIONS =>
          case TransRec.Options is 
            when WB_CTI      =>   TransRec.IntFromModel  <= to_integer(BurstCti) ;
            when WB_LOCK     =>   TransRec.IntFromModel  <= 0 when Lock = '0' else 1 ; 
            when WB_DELAY    =>   TransRec.IntFromModel  <= StaticDelayCycles ; 
            when WB_PIPELINE =>   TransRec.BoolFromModel <= PipeMode ; 
            when others      =>   Alert(ModelID, ClassifyUnimplementedOperation(TransRec) & " Option: " & to_string(TransRec.Options), FAILURE) ; 
          end case ; 

        -- The End -- Done
        when others =>
          DoDirectiveTransactions (
            TransRec              => TransRec             ,
            Clk                   => Clk                  ,
            ModelID               => ModelID              ,
            UseCoverageDelays     => UseCoverageDelays    ,
            DelayCovID            => ArrDelayCovID        ,
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

  iAck <= WishboneBus.Ack or WishboneBus.Rty or WishboneBus.Err  ;
  
--!!  CycleDone <=
--!!    not WishboneBus.Stall when PipeMode else iAck ; 
--!!    
--!!  ------------------------------------------------------------
--!!  --  Generate Cyc signal
--!!  --    Pipelined address and write data complete on not Stall 
--!!  --    Cyc and read data not complete until Ack
--!!  --    Hence Cyc is held from Transaction Start to Transaction Done, 
--!!  --    Except during a burst where it is also held asserted between beats
--!!  ------------------------------------------------------------
--!!  CycProc : process
--!!  begin
--!!    WishboneBus.Cyc <= '0'  ;  -- Initial
--!!    CycLoop : loop 
--!!      -- These only change when aligned to clock
--!!      wait on TransactionStartCount, TransactionDoneCount, Burst ; 
--!!      
--!!      if TransactionStartCount /= TransactionDoneCount then  -- Nominally TransactionStartCount > TransactionDoneCount
--!!        WishboneBus.Cyc <= '1' after tpd_clk_Cyc ;
--!!      elsif Burst = '1' then 
--!!        WishboneBus.Cyc <= '1' after tpd_clk_Cyc ;        
--!!      else 
--!!        WishboneBus.Cyc <= '0' after tpd_clk_Cyc ;
--!!      end if ; 
--!!    end loop CycLoop ; 
--!!  end process CycProc ; 
--!!
--!!
--!!
--!!  ------------------------------------------------------------
--!!  --  EndTransactionHandler
--!!  --    Receive Read Data Transactions
--!!  ------------------------------------------------------------
--!!  EndTransactionHandler : process
--!!    variable LocalWe : std_logic_vector(1 downto 1) ; 
--!!  begin
--!!  
--!!    loop 
--!!      wait until  rising_edge(Clk) and iAck = '1'  ;
--!!      
--!!      if TransactionStartCount = TransactionDoneCount then 
--!!        -- Ack received when transaction not active
--!!        -- Figure 4-7 (B.3 pdf) (Figure 29 html) Constant address burst 
--!!        -- implies that this is a stall initiated by Stb being inactive.
--!!        -- Hard to resolve this in conjunction with B.4 pipelining, 
--!!        -- However, we do know, so lets ignore it.
--!!        Alert(ModelId, "Received Ack with no transaction pending", WARNING) ; 
--!!        next ; 
--!!      end if ; 
--!!      
--!!      LocalWe := pop(EndTransactionFifo) ;
--!!
--!!      if LocalWe = "0"  then
--!!        AlertIf(ModelId, ReadDataReceiveCount = ReadDataExpectCount, "EndTransactionHandler:  Received Data, but not expecting") ;
--!!        push(ReadDataFifo, WishboneBus.iDat) ;
--!!        increment(ReadDataReceiveCount) ;
--!!      end if ;
--!!      
--!!      increment(TransactionDoneCount) ;
--!!      wait for 0 ns ; -- Allow ReadDataReceiveCount to update
--!!    end loop ; 
--!!  end process EndTransactionHandler ;

end architecture VerificationComponent ;
