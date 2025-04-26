--
--  File Name:         Tb_BasicReadWrite.vhd
--  Design Unit Name:  Architecture of TestCtrl
--  Revision:          OSVVM MODELS STANDARD VERSION
--
--  Maintainer:        Jim Lewis      email:  jim@synthworks.com
--  Contributor(s):
--     Jim Lewis      jim@synthworks.com
--
--
--  Description:
--      Basic Register Read/Write for AddressBus Interfaces
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

architecture BasicReadWrite of TestCtrl is
 
begin

  ------------------------------------------------------------
  -- ControlProc
  --   Set up AlertLog and wait for end of test
  ------------------------------------------------------------
  ControlProc : process
  begin
    -- Initialization of test
    SetTestName("Tb_BasicReadWrite") ;
    SetLogEnable(PASSED, TRUE) ;    -- Enable PASSED logs
    SetLogEnable(INFO, TRUE) ;    -- Enable INFO logs

    -- Wait for testbench initialization 
    wait for 0 ns ;  wait for 0 ns ;
    TranscriptOpen ;
    SetTranscriptMirror(TRUE) ; 

    -- Wait for Design Reset
    wait until nReset = '1' ;  
    -- ClearAlerts ;

    -- Wait for test to finish
    WaitForBarrier(OsvvmTestDone, 35 ms) ;    
    
    TranscriptClose ; 
    -- Printing differs in different simulators due to differences in process order execution
    -- AffirmIfTranscriptsMatch("Path-To-ValidatedResults") ; 

    EndOfTestReports(TimeOut => now >= 35 ms) ; 
    std.env.stop ; 
    wait ; 
  end process ControlProc ; 

  ------------------------------------------------------------
  -- ManagerProc
  --   Generate transactions for AxiManager
  ------------------------------------------------------------
  ManagerProc : process
    variable Addr : std_logic_vector(ADDR_WIDTH-1 downto 0) := ADDR_ZERO ;
    variable Data : std_logic_vector(DATA_WIDTH-1 downto 0) ;
    constant TEST_ADDR_INCREMENT : integer := 16#20# ;
  begin
    wait until nReset = '1' ;  
    WaitForClock(ManagerRec, 2) ; 
    
    log("Write, Read, ReadCheck words, 4 Bytes") ;
    Addr := ADDR_ZERO ; 
    Write(ManagerRec,   Addr, X"5555_5555" ) ;
    Read(ManagerRec,    Addr, Data) ;
    AffirmIfEqual(Data, X"5555_5555", "Manager Read Data: ") ;


    log("Read with 1 Byte, and ByteAddr = 0, 1, 2, 3") ; 
    Addr := Addr + WORD_ADDR_INCREMENT ;
    Write    (ManagerRec, Addr, X"A4A3A2A1" ) ;
    ReadCheck(ManagerRec, Addr, X"A4A3A2A1" ) ;

    Read(ManagerRec,  Addr,     Data(7 downto 0)) ;
    AffirmIfEqual(Data(7 downto 0), X"A1", "Manager Read Data: ") ;
    Read(ManagerRec,  Addr + 1, Data(7 downto 0)) ;
    AffirmIfEqual(Data(7 downto 0), X"A2", "Manager Read Data: ") ;
    Read(ManagerRec,  Addr + 2, Data(7 downto 0)) ;
    AffirmIfEqual(Data(7 downto 0), X"A3", "Manager Read Data: ") ;
    Read(ManagerRec,  Addr + 3, Data(7 downto 0)) ;
    AffirmIfEqual(Data(7 downto 0), X"A4", "Manager Read Data: ") ;

    log("Read with 2 Bytes, and ByteAddr = 0, 1, 2") ; 
    Addr := Addr + WORD_ADDR_INCREMENT ;
    Write    (ManagerRec, Addr, X"B4B3B2B1" ) ;
    Read(ManagerRec,  Addr,     Data(15 downto 0)) ;
    AffirmIfEqual(Data(15 downto 0), X"B2B1", "Manager Read Data: ") ;
    Read(ManagerRec,  Addr + 1, Data(15 downto 0)) ;
    AffirmIfEqual(Data(15 downto 0), X"B3B2", "Manager Read Data: ") ;
    Read(ManagerRec,  Addr + 2, Data(15 downto 0)) ;
    AffirmIfEqual(Data(15 downto 0), X"B4B3", "Manager Read Data: ") ;

    log("Read with 3 Bytes, and ByteAddr = 0, 1") ; 
    Addr := Addr + WORD_ADDR_INCREMENT ;
    Write    (ManagerRec, Addr, X"C4C3C2C1" ) ;
    Read(ManagerRec,  Addr,     Data(23 downto 0)) ;
    AffirmIfEqual(Data(23 downto 0), X"C3C2C1", "Manager Read Data: ") ;
    Read(ManagerRec,  Addr + 1, Data(23 downto 0)) ;
    AffirmIfEqual(Data(23 downto 0), X"C4C3C2", "Manager Read Data: ") ;

    log("Write and ReadCheck with 1 Byte, and ByteAddr = 0, 1, 2, 3") ; 
    Addr := ADDR_ZERO + TEST_ADDR_INCREMENT ; 
    Write(ManagerRec, Addr,     X"D1" ) ;
    Write(ManagerRec, Addr + 1, X"D2" ) ;
    Write(ManagerRec, Addr + 2, X"D3" ) ;
    Write(ManagerRec, Addr + 3, X"D4" ) ;

    Read(ManagerRec,    Addr, Data) ;
    AffirmIfEqual(Data, X"D4D3_D2D1", "Manager Read Data: ") ;
    
    ReadCheck(ManagerRec,  Addr,     X"D1") ;
    ReadCheck(ManagerRec,  Addr + 1, X"D2") ;
    ReadCheck(ManagerRec,  Addr + 2, X"D3") ;
    ReadCheck(ManagerRec,  Addr + 3, X"D4") ;

    log("Write and Read with 2 Bytes, and ByteAddr = 0, 1, 2") ; 
    Addr := ADDR_ZERO + 2*TEST_ADDR_INCREMENT ; 
    Write(ManagerRec, Addr,     X"1211" ) ;
    Addr := Addr + WORD_ADDR_INCREMENT ;
    Write(ManagerRec, Addr + 1, X"23_22" ) ;
    Addr := Addr + WORD_ADDR_INCREMENT ;
    Write(ManagerRec, Addr + 2, X"3433" ) ;

    Addr := ADDR_ZERO + 2*TEST_ADDR_INCREMENT ; 
    ReadCheck(ManagerRec, Addr,     X"1211" ) ;
    Addr := Addr + WORD_ADDR_INCREMENT ;
    ReadCheck(ManagerRec, Addr + 1, X"23_22" ) ;
    Addr := Addr + WORD_ADDR_INCREMENT ;
    ReadCheck(ManagerRec, Addr + 2, X"3433" ) ;

    log("Write and Read with 3 Bytes and ByteAddr = 0. 1") ;
    Addr := ADDR_ZERO + 3*TEST_ADDR_INCREMENT ; 
    Write(ManagerRec, Addr,                           X"43_4241" ) ;
    Write(ManagerRec, Addr + WORD_ADDR_INCREMENT + 1, X"5453_52" ) ;

    ReadCheck(ManagerRec, Addr,                           X"43_4241" ) ;
    ReadCheck(ManagerRec, Addr + WORD_ADDR_INCREMENT + 1, X"5453_52" ) ;
    
    -- Wait for outputs to propagate and signal OsvvmTestDone
    WaitForClock(ManagerRec, 2) ;
    WaitForBarrier(OsvvmTestDone) ;
    wait ;
  end process ManagerProc ;

end BasicReadWrite ;

Configuration Tb_BasicReadWrite of TestHarness is
  for Structural
    for TestCtrl_1 : TestCtrl
      use entity work.TestCtrl(BasicReadWrite) ; 
    end for ; 
  end for ; 
end Tb_BasicReadWrite ; 