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