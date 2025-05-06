# Wishbone
Wishbone VC are currently beta level.

## src
The src directory contains the wishbone VC and support packages.   

### WishboneManager
  Wishbone Manager VC.   Supports Wishbone 3 and 4.  
  For Wishbone 4, set generic WISHBONE_PIPELINED to TRUE.
  
### WishboneRegisteredSubordinate
  Wishbone 3 Subordinate.  Ack is always registered, and hence, nevers responds in one clock cycle.
  Will work with a Wishbone 4 manager since it makes Stall = not Ack.
  
### WishboneManagerBlocking
  Blocking Wishbone Manager VC. 
  Only supports simple blocking read and write cycles.
  Intended more as an example than an actual VC.
  
### WishboneInterfacePkg
  Defines a record with all wishbone signals with type WishboneRecType
  
### WishboneGenericSignalsPkg
  Intended as a simplified method to define signals required to use a wishbone VC.
  
### WishbonePassThru
  Used as a stand in for a DUT in the testbench.   
  Connects a Wishbone Manager to a Subordinate.
  Allows the wishbone testbench to demonstrate how to connect up the wishbone VC.
  
## testbench
  Define the TestHarness and TestCtrl used to test wishbone.
  
## TestCases
  Defines architectures of TestCtrl used as test cases to test the wishbone VC.
  
## build.pro
  Builds wishbone sources.   Called by OsvvmLibraries/OsvvmLibraries.pro
  
## RunAllTests.pro
  Runs the Wishbone test suite.
  
  

 
## Copyright and License
Copyright (C) 2025 by [SynthWorks Design Inc.](http://www.synthworks.com/)   
Copyright (C) 2025 by [OSVVM contributors](CONTRIBUTOR.md)   

This file is part of OSVVM.

    Licensed under Apache License, Version 2.0 (the "License")
    You may not use this file except in compliance with the License.
    You may obtain a copy of the License at

  [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
