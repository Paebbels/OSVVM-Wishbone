--
--  File Name:         Tb_RandomReadWrite.vhd
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

architecture RandomReadWrite of TestCtrl is
 
begin

  ------------------------------------------------------------
  -- ControlProc
  --   Set up AlertLog and wait for end of test
  ------------------------------------------------------------
  ControlProc : process
  begin
    -- Initialization of test
    SetTestName("Tb_RandomReadWrite") ;
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
    variable ID : AlertLogIDType ; 
  begin
    SetUseRandomDelays(ManagerRec) ; 
    wait until nReset = '1' ;  
    WaitForClock(ManagerRec, 2) ; 
    ID := NewID("Tb") ;

    -- Use Coverage based delays

    BlankLine ; 
    Print("-----------------------------------------------------------------") ;
    log("Write and Read 32 words. Addr = 0000_0000 + 16*i.") ;
    BlankLine ; 
    for I in 0 to 31 loop
      WriteAsync  ( ManagerRec, X"0000_0000" + 16*I, X"0000_0000" + 16*I ) ;
    end loop ;

    WaitForTransaction(ManagerRec) ; 

    for I in 0 to 31 loop
      ReadAddressAsync ( ManagerRec, X"0000_0000" + 16*I) ;
    end loop ;
    for I in 0 to 31 loop
      ReadCheckData    ( ManagerRec, X"0000_0000" + 16*I ) ;
    end loop ;

    BlankLine ; 
    Print("-----------------------------------------------------------------") ;
    log("Write and Read 3 bursts of 16 words. Addr = 0000_1000 + 256*i.") ;
    BlankLine ; 
    for i in 1 to 3 loop 
      WriteBurstIncrementAsync    (ManagerRec, X"0000_0000" + 256*I, X"0000_1000" + 16*I, 16) ;
    end loop ;

    WaitForTransaction(ManagerRec) ; 
      
    for I in 1 to 3 loop
      ReadCheckBurstIncrement(ManagerRec, X"0000_0000" + 256*I, X"0000_1000" + 16*I, 16) ;
    end loop ;

    -- Wait for outputs to propagate and signal OsvvmTestDone
    WaitForClock(ManagerRec, 2) ;
    WaitForBarrier(OsvvmTestDone) ;
    wait ;
  end process ManagerProc ;

  ------------------------------------------------------------
  -- MemoryProc
  --   Generate transactions for AxiSubordinate
  ------------------------------------------------------------
  MemoryProc : process
    variable Addr : std_logic_vector(ADDR_WIDTH-1 downto 0) ;
    variable Data : std_logic_vector(DATA_WIDTH-1 downto 0) ;
  begin
    SetUseRandomDelays(SubordinateRec) ; 
    WaitForClock(SubordinateRec, 2) ;

    -- Wait for outputs to propagate and signal TestDone
    WaitForClock(SubordinateRec, 2) ;
    WaitForBarrier(TestDone) ;
    wait ;
  end process MemoryProc ;


end RandomReadWrite ;

Configuration Tb_RandomReadWrite of TestHarness is
  for Structural
    for TestCtrl_1 : TestCtrl
      use entity work.TestCtrl(RandomReadWrite) ; 
    end for ; 
  end for ; 
end Tb_RandomReadWrite ; 