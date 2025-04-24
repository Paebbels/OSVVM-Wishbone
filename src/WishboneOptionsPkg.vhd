--
--  File Name:         WishboneOptionsPkg.vhd
--  Design Unit Name:  WishboneOptionsPkg
--  Revision:          OSVVM MODELS STANDARD VERSION
--
--  Maintainer:        Jim Lewis      email:  jim@synthworks.com
--  Contributor(s):
--     Jim Lewis      jim@synthworks.com
--
--
--  Description:
--      Defines types, constants, and subprograms used for
--      accessing VC internal settings and options
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

library OSVVM_Common ;
    context OSVVM_Common.OsvvmCommonContext ;

use work.WishboneInterfacePkg.all ;

package WishboneOptionsPkg is

  type WishboneUnresolvedOptionsType is (
    -- Wishbone Model Options
    PIPELINED,


    -- Marker
    OPTIONS_MARKER,

-- Wishbone Interface Settings


    --
    -- The End -- Done
    THE_END
  ) ;
  type WishboneUnresolvedOptionsVectorType is array (natural range <>) of WishboneUnresolvedOptionsType ;
  -- alias resolved_max is maximum[ WishboneUnresolvedOptionsVectorType return WishboneUnresolvedOptionsType] ;
  function resolved_max(A : WishboneUnresolvedOptionsVectorType) return WishboneUnresolvedOptionsType ;

  subtype WishboneOptionsType is resolved_max WishboneUnresolvedOptionsType ;


  --
  --  Abstraction Layer to support SetModelOptions using enumerated values
  --
  ------------------------------------------------------------
  procedure SetWishboneOptions (
  ------------------------------------------------------------
    signal   TransactionRec : InOut AddressBusRecType ;
    constant Option         : In    WishboneOptionsType ;
    constant OptVal         : In    boolean
  ) ;

  ------------------------------------------------------------
  procedure SetWishboneOptions (
  ------------------------------------------------------------
    signal   TransactionRec : InOut AddressBusRecType ;
    constant Option         : In    WishboneOptionsType ;
    constant OptVal         : In    std_logic
  ) ;

  ------------------------------------------------------------
  procedure SetWishboneOptions (
  ------------------------------------------------------------
    signal   TransactionRec : InOut AddressBusRecType ;
    constant Option         : In    WishboneOptionsType ;
    constant OptVal         : In    integer
  ) ;

  ------------------------------------------------------------
  procedure SetWishboneOptions (
  ------------------------------------------------------------
    signal   TransactionRec : InOut AddressBusRecType ;
    constant Option         : In    WishboneOptionsType ;
    constant OptVal         : In    std_logic_vector
  ) ;

  ------------------------------------------------------------
  procedure GetWishboneOptions (
  ------------------------------------------------------------
    signal   TransactionRec : InOut AddressBusRecType ;
    constant Option         : In    WishboneOptionsType ;
    variable OptVal         : Out   boolean
  ) ;

  ------------------------------------------------------------
  procedure GetWishboneOptions (
  ------------------------------------------------------------
    signal   TransactionRec : InOut AddressBusRecType ;
    constant Option         : In    WishboneOptionsType ;
    variable OptVal         : Out   std_logic
  ) ;

  ------------------------------------------------------------
  procedure GetWishboneOptions (
  ------------------------------------------------------------
    signal   TransactionRec : InOut AddressBusRecType ;
    constant Option         : In    WishboneOptionsType ;
    variable OptVal         : Out   integer
  ) ;

  ------------------------------------------------------------
  procedure GetWishboneOptions (
  ------------------------------------------------------------
    signal   TransactionRec : InOut AddressBusRecType ;
    constant Option         : In    WishboneOptionsType ;
    variable OptVal         : Out   std_logic_vector
  ) ;

  --
  -- Wishbone Verification Component Support Subprograms
  --
  ------------------------------------------------------------
  impure function to_integer (Operation : WishboneOptionsType) return integer ;
  function IsAxiParameter (Operation : WishboneOptionsType) return boolean ;
  function IsAxiInterface (Operation : WishboneOptionsType) return boolean ; 

  ------------------------------------------------------------
  procedure SetWishboneParameter (
  -----------------------------------------------------------
    constant Params        : in    ModelParametersIDType ;
    constant Operation     : in    WishboneOptionsType ;
    constant OptVal        : in    boolean
  ) ;

  ------------------------------------------------------------
  procedure SetWishboneParameter (
  -----------------------------------------------------------
    constant Params        : in    ModelParametersIDType ;
    constant Operation     : in    WishboneOptionsType ;
    constant OptVal        : in    std_logic
  ) ;

  ------------------------------------------------------------
  procedure SetWishboneParameter (
  -----------------------------------------------------------
    constant Params        : in    ModelParametersIDType ;
    constant Operation     : in    WishboneOptionsType ;
    constant OptVal        : in    integer
  ) ;

  ------------------------------------------------------------
  procedure SetWishboneParameter (
  -----------------------------------------------------------
    constant Params        : in    ModelParametersIDType ;
    constant Operation     : in    WishboneOptionsType ;
    constant OptVal        : in    std_logic_vector
  ) ;

  ------------------------------------------------------------
  impure function GetWishboneParameter (
  -----------------------------------------------------------
    constant Params        : in    ModelParametersIDType ;
    constant Operation     : in    WishboneOptionsType 
  ) return boolean ;

  ------------------------------------------------------------
  impure function GetWishboneParameter (
  -----------------------------------------------------------
    constant Params        : in    ModelParametersIDType ;
    constant Operation     : in    WishboneOptionsType 
  ) return integer ;

  ------------------------------------------------------------
  impure function GetWishboneParameter (
  -----------------------------------------------------------
    constant Params        : in    ModelParametersIDType ;
    constant Operation     : in    WishboneOptionsType 
  ) return std_logic_vector ;
  
  ------------------------------------------------------------
  impure function GetWishboneParameter (
  -----------------------------------------------------------
    constant Params        : in    ModelParametersIDType ;
    constant Operation     : in    WishboneOptionsType ;
    constant Size          : in    natural
  ) return std_logic_vector ;
  
  ------------------------------------------------------------
  procedure InitAxiOptions (
  -----------------------------------------------------------
    constant Params        : in ModelParametersIDType 
  ) ;

  ------------------------------------------------------------
  procedure InitAxiOptions (
  -----------------------------------------------------------
    signal Params        : InOut ModelParametersIDType ;
           Name          : in    string ; 
           ParentID      : in    AlertLogIDType
  ) ;
  
  ------------------------------------------------------------
  procedure SetWishboneInterfaceDefault (
  -----------------------------------------------------------
    variable WishboneBus   : InOut WishboneRecType ;
    constant Operation     : In    WishboneOptionsType ;
    constant OptVal        : In    integer
  ) ;

  ------------------------------------------------------------
  impure function GetWishboneInterfaceDefault (
  -----------------------------------------------------------
    constant WishboneBus   : in  WishboneRecType ;
    constant Operation     : in  WishboneOptionsType
  ) return integer ;


end package WishboneOptionsPkg ;

-- /////////////////////////////////////////////////////////////////////////////////////////
-- /////////////////////////////////////////////////////////////////////////////////////////
-- /////////////////////////////////////////////////////////////////////////////////////////
-- /////////////////////////////////////////////////////////////////////////////////////////
-- /////////////////////////////////////////////////////////////////////////////////////////
-- /////////////////////////////////////////////////////////////////////////////////////////

package body WishboneOptionsPkg is

  function resolved_max(A : WishboneUnresolvedOptionsVectorType) return WishboneUnresolvedOptionsType is
  begin
    return maximum(A) ;
  end function resolved_max ;

--   function resolved_max ( s : WishboneUnresolvedRespVectorEnumType) return WishboneUnresolvedRespEnumType is
--   begin
--     return maximum(s) ;
--   end function resolved_max ; 

  ------------------------------------------------------------
  --
  --  Abstraction Layer to support SetModelOptions using enumerated values
  --
  ------------------------------------------------------------
  procedure SetWishboneOptions (
  ------------------------------------------------------------
    signal   TransactionRec : InOut AddressBusRecType ;
    constant Option         : In    WishboneOptionsType ;
    constant OptVal         : In    boolean
  ) is
  begin
    SetModelOptions(TransactionRec, WishboneOptionsType'POS(Option), boolean'pos(OptVal)) ;
  end procedure SetWishboneOptions ;

  ------------------------------------------------------------
  procedure SetWishboneOptions (
  ------------------------------------------------------------
    signal   TransactionRec : InOut AddressBusRecType ;
    constant Option         : In    WishboneOptionsType ;
    constant OptVal         : In    std_logic
  ) is
  begin
    SetModelOptions(TransactionRec, WishboneOptionsType'POS(Option), std_logic'pos(OptVal)) ;
  end procedure SetWishboneOptions ;

  ------------------------------------------------------------
  procedure SetWishboneOptions (
  ------------------------------------------------------------
    signal   TransactionRec : InOut AddressBusRecType ;
    constant Option         : In    WishboneOptionsType ;
    constant OptVal         : In    integer
  ) is
  begin
    SetModelOptions(TransactionRec, WishboneOptionsType'POS(Option), OptVal) ;
  end procedure SetWishboneOptions ;

  ------------------------------------------------------------
  procedure SetWishboneOptions (
  ------------------------------------------------------------
    signal   TransactionRec : InOut AddressBusRecType ;
    constant Option         : In    WishboneOptionsType ;
    constant OptVal         : In    std_logic_vector
  ) is
  begin
    SetModelOptions(TransactionRec, WishboneOptionsType'POS(Option), OptVal) ;
  end procedure SetWishboneOptions ;

  ------------------------------------------------------------
  procedure GetWishboneOptions (
  ------------------------------------------------------------
    signal   TransactionRec : InOut AddressBusRecType ;
    constant Option         : In    WishboneOptionsType ;
    variable OptVal         : Out   boolean
  ) is
    variable IntOptVal : integer ;
  begin
    GetModelOptions(TransactionRec, WishboneOptionsType'POS(Option), IntOptVal) ;
    OptVal := IntOptVal >= 1 ;
  end procedure GetWishboneOptions ;

  ------------------------------------------------------------
  procedure GetWishboneOptions (
  ------------------------------------------------------------
    signal   TransactionRec : InOut AddressBusRecType ;
    constant Option         : In    WishboneOptionsType ;
    variable OptVal         : Out   std_logic
  ) is
    variable IntOptVal : integer ;
  begin
    GetModelOptions(TransactionRec, WishboneOptionsType'POS(Option), IntOptVal) ;
    OptVal := std_logic'val(IntOptVal) ;
  end procedure GetWishboneOptions ;

  ------------------------------------------------------------
  procedure GetWishboneOptions (
  ------------------------------------------------------------
    signal   TransactionRec : InOut AddressBusRecType ;
    constant Option         : In    WishboneOptionsType ;
    variable OptVal         : Out   integer
  ) is
  begin
    GetModelOptions(TransactionRec, WishboneOptionsType'POS(Option), OptVal) ;
  end procedure GetWishboneOptions ;

  ------------------------------------------------------------
  procedure GetWishboneOptions (
  ------------------------------------------------------------
    signal   TransactionRec : InOut AddressBusRecType ;
    constant Option         : In    WishboneOptionsType ;
    variable OptVal         : Out   std_logic_vector
  ) is
  begin
    GetModelOptions(TransactionRec, WishboneOptionsType'POS(Option), OptVal) ;
  end procedure GetWishboneOptions ;

  --
  -- Wishbone Verification Component Support Subprograms
  --
  ------------------------------------------------------------
  impure function to_integer (Operation : WishboneOptionsType) return integer is 
  -----------------------------------------------------------
  begin
    return WishboneOptionsType'POS(Operation) ;
  end function to_integer ;

  ------------------------------------------------------------
  function IsAxiParameter (Operation : WishboneOptionsType) return boolean is 
  -----------------------------------------------------------
  begin
    return (Operation < OPTIONS_MARKER) ;
  end function IsAxiParameter ;

  ------------------------------------------------------------
  function IsAxiInterface (Operation : WishboneOptionsType) return boolean is 
  ------------------------------------------------------------
  begin
    return (Operation > OPTIONS_MARKER) ;
  end function IsAxiInterface ;

  ------------------------------------------------------------
  procedure SetWishboneParameter (
  -----------------------------------------------------------
    constant Params        : in    ModelParametersIDType ;
    constant Operation     : in    WishboneOptionsType ;
    constant OptVal        : in    boolean
  ) is
  begin
    Set(Params, WishboneOptionsType'POS(Operation), OptVal) ;
  end procedure SetWishboneParameter ;

  ------------------------------------------------------------
  procedure SetWishboneParameter (
  -----------------------------------------------------------
    constant Params        : in    ModelParametersIDType ;
    constant Operation     : in    WishboneOptionsType ;
    constant OptVal        : in    std_logic
  ) is
  begin
    Set(Params, WishboneOptionsType'POS(Operation), std_logic'pos(OptVal)) ;
  end procedure SetWishboneParameter ;

  ------------------------------------------------------------
  procedure SetWishboneParameter (
  -----------------------------------------------------------
    constant Params        : in    ModelParametersIDType ;
    constant Operation     : in    WishboneOptionsType ;
    constant OptVal        : in    integer
  ) is
  begin
    Set(Params, WishboneOptionsType'POS(Operation), OptVal) ;
  end procedure SetWishboneParameter ;

  ------------------------------------------------------------
  procedure SetWishboneParameter (
  -----------------------------------------------------------
    constant Params        : in    ModelParametersIDType ;
    constant Operation     : in    WishboneOptionsType ;
    constant OptVal        : in    std_logic_vector
  ) is
  begin
    Set(Params, WishboneOptionsType'POS(Operation), OptVal) ;
  end procedure SetWishboneParameter ;

  ------------------------------------------------------------
  impure function GetWishboneParameter (
  -----------------------------------------------------------
    constant Params        : in    ModelParametersIDType ;
    constant Operation     : in    WishboneOptionsType 
  ) return boolean is
    variable IntResult : integer ; 
  begin
    IntResult := Get(Params, WishboneOptionsType'POS(Operation)) ; 
    return IntResult > 0 ;
  end function GetWishboneParameter ;

  ------------------------------------------------------------
  impure function GetWishboneParameter (
  -----------------------------------------------------------
    constant Params        : in    ModelParametersIDType ;
    constant Operation     : in    WishboneOptionsType 
  ) return integer is
  begin
    return Get(Params, WishboneOptionsType'POS(Operation)) ;
  end function GetWishboneParameter ;

  ------------------------------------------------------------
  impure function GetWishboneParameter (
  -----------------------------------------------------------
    constant Params        : in    ModelParametersIDType ;
    constant Operation     : in    WishboneOptionsType 
  ) return std_logic_vector is 
  begin
    return Get(Params, WishboneOptionsType'POS(Operation)) ;
  end function GetWishboneParameter ;
  
  ------------------------------------------------------------
  impure function GetWishboneParameter (
  -----------------------------------------------------------
    constant Params        : in    ModelParametersIDType ;
    constant Operation     : in    WishboneOptionsType ;
    constant Size          : in    natural
  ) return std_logic_vector is 
  begin
    return Get(Params, WishboneOptionsType'POS(Operation), Size) ;
  end function GetWishboneParameter ;
  
  ------------------------------------------------------------
  procedure InitAxiOptions (
  -----------------------------------------------------------
    constant Params        : in ModelParametersIDType 
  ) is
  begin
    -- Wishbone Model Options
    -- Ready timeout

  end procedure InitAxiOptions ;

  ------------------------------------------------------------
  procedure InitAxiOptions (
  -----------------------------------------------------------
    signal Params        : InOut ModelParametersIDType ;
           Name          : in    string ; 
           ParentID      : in    AlertLogIDType
  ) is
    variable vParams : ModelParametersIDType ; 
  begin
    -- 
    -- Size the Data structure, such that it creates 1 parameter for each option
    vParams := NewID(Name, to_integer(OPTIONS_MARKER), ParentID); 
    Params  <= vParams ; 
    InitAxiOptions(vParams) ; 
    
  end procedure InitAxiOptions ;

  ------------------------------------------------------------
  procedure SetWishboneInterfaceDefault (
  -----------------------------------------------------------
    variable WishboneBus   : InOut WishboneRecType ;
    constant Operation     : In    WishboneOptionsType ;
    constant OptVal        : In    integer
  ) is
  begin
    case Operation is
      -- AXI
      -- The End -- Done
      when others =>
        Alert("Unknown model option", FAILURE) ;

    end case ;
  end procedure SetWishboneInterfaceDefault ;

  ------------------------------------------------------------
  impure function GetWishboneInterfaceDefault (
  -----------------------------------------------------------
    constant WishboneBus   : in  WishboneRecType ;
    constant Operation     : in  WishboneOptionsType
  ) return integer is
  begin
    case Operation is
      -- Write Address
      -- AXI
      -- The End -- Done
      when others =>
--        Alert(ModelID, "Unknown model option", FAILURE) ;
        Alert("Unknown model option", FAILURE) ;
        return integer'left ;

    end case ;
  end function GetWishboneInterfaceDefault ;

end package body WishboneOptionsPkg ;