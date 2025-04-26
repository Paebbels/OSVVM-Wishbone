--
--  File Name:         TbRegister_BasicReadWrite.vhd
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
    SetTestName("TbRegister_BasicReadWrite") ;
    SetLogEnable(PASSED, TRUE) ;    -- Enable PASSED logs
    SetLogEnable(INFO, TRUE) ;    -- Enable INFO logs

    -- Wait for testbench initialization 
    wait for 0 ns ;  wait for 0 ns ;
    TranscriptOpen ;
    SetTranscriptMirror(TRUE) ; 

    -- Wait for Design Reset
    wait until nReset = '1' ;  
    ClearAlerts ;

    -- Wait for test to finish
    WaitForBarrier(OsvvmTestDone, 35 ms) ;
  --  AlertIf(now >= 35 ms, "Test finished due to timeout") ;  -- now part of EndOfTestReports
  --  AlertIf(GetAffirmCount < 1, "Test is not Self-Checking"); -- Reporting Checks This
    
    
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
    variable Data : std_logic_vector(DATA_WIDTH-1 downto 0) ;
  begin
    wait until nReset = '1' ;  
    WaitForClock(ManagerRec, 2) ; 
    log("Write and Read with ByteAddr = 0, 4 Bytes") ;
    Write(ManagerRec,   X"0000_0010", X"5555_5555" ) ;
    Read(ManagerRec,    X"0000_0010", Data) ;
    AffirmIfEqual(Data, X"5555_5555", "Manager Read Data: ") ;
    
    log("Write and Read with 1 Byte, and ByteAddr = 0, 1, 2, 3") ; 
    Write(ManagerRec, X"0000_0020", X"11" ) ;
    Write(ManagerRec, X"0000_0021", X"22" ) ;
    Write(ManagerRec, X"0000_0022", X"33" ) ;
    Write(ManagerRec, X"0000_0023", X"44" ) ;

    Read(ManagerRec,    X"0000_0020", Data) ;
    AffirmIfEqual(Data, X"4433_2211", "Manager Read Data: ") ;
    
    Read(ManagerRec,  X"0000_0020", Data(7 downto 0)) ;
    AffirmIfEqual(Data(7 downto 0), X"11", "Manager Read Data: ") ;
    Read(ManagerRec,  X"0000_0021", Data(7 downto 0)) ;
    AffirmIfEqual(Data(7 downto 0), X"22", "Manager Read Data: ") ;
    Read(ManagerRec,  X"0000_0022", Data(7 downto 0)) ;
    AffirmIfEqual(Data(7 downto 0), X"33", "Manager Read Data: ") ;
    Read(ManagerRec,  X"0000_0023", Data(7 downto 0)) ;
    AffirmIfEqual(Data(7 downto 0), X"44", "Manager Read Data: ") ;

    
--    log("Write and Read with 2 Bytes, and ByteAddr = 0, 1, 2") ;
--    Write(ManagerRec, X"BBBB_BBB0", X"2211" ) ;
--    Write(ManagerRec, X"BBBB_BBB1", X"33_22" ) ;
--    Write(ManagerRec, X"BBBB_BBB2", X"4433" ) ;
--
--    Read(ManagerRec,  X"1111_1110", Data(15 downto 0)) ;
--    AffirmIfEqual(Data(15 downto 0), X"BBAA", "Manager Read Data: ") ;
--    Read(ManagerRec,  X"1111_1111", Data(15 downto 0)) ;
--    AffirmIfEqual(Data(15 downto 0), X"CCBB", "Manager Read Data: ") ;
--    Read(ManagerRec,  X"1111_1112", Data(15 downto 0)) ;
--    AffirmIfEqual(Data(15 downto 0), X"DDCC", "Manager Read Data: ") ;
--
--    log("Write and Read with 3 Bytes and ByteAddr = 0. 1") ;
--    Write(ManagerRec, X"CCCC_CCC0", X"33_2211" ) ;
--    Write(ManagerRec, X"CCCC_CCC1", X"4433_22" ) ;
--
--    Read(ManagerRec,  X"1111_1110", Data(23 downto 0)) ;
--    AffirmIfEqual(Data(23 downto 0), X"CC_BBAA", "Manager Read Data: ") ;
--    Read(ManagerRec,  X"1111_1111", Data(23 downto 0)) ;
--    AffirmIfEqual(Data(23 downto 0), X"DDCC_BB", "Manager Read Data: ") ;
    
    -- Wait for outputs to propagate and signal OsvvmTestDone
    WaitForClock(ManagerRec, 2) ;
    WaitForBarrier(OsvvmTestDone) ;
    wait ;
  end process ManagerProc ;


end BasicReadWrite ;

Configuration TbRegister_BasicReadWrite of TbRegister is
  for TestHarness
    for TestCtrl_1 : TestCtrl
      use entity work.TestCtrl(BasicReadWrite) ; 
    end for ; 
  end for ; 
end TbRegister_BasicReadWrite ; 