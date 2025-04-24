--
--  File Name:         WishbonePassThru.vhd
--  Design Unit Name:  WishbonePassThru
--  Revision:          OSVVM MODELS STANDARD VERSION
--
--  Maintainer:        Jim Lewis      email:  jim@synthworks.com
--  Contributor(s):
--     Jim Lewis      jim@synthworks.com
--
--
--  Description:
--     DUT pass thru for Wishbone VC testing 
--     Used to demonstrate DUT connections
--
--
--  Developed by:
--        SynthWorks Design Inc.
--        VHDL Training Classes
--        http://www.SynthWorks.com
--
--  Revision History:
--    Date      Version    Description
--    04/2025   2025.04    Initial
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

  use work.WishboneInterfacePkg.all ;

entity WishbonePassThru is
  port (
    -- Manager Interface 
    mCyc_o       : out std_logic ; 
    mLock_o      : out std_logic ; 
    mStb_o       : out std_logic ; 
    mWe_o        : out std_logic ; 
    mAck_i       : in  std_logic ; 
    mErr_i       : in  std_logic ; 
    mRty_i       : in  std_logic ; 
    mStall_i     : in  std_logic ; 
    mAdr_o       : out std_logic_vector ; 
    mDat_o       : out std_logic_vector ; 
    mDat_i       : in  std_logic_vector ; 
    mSel_o       : out std_logic_vector ; 
    mCti_o       : out std_logic_vector(2 downto 0) ;

    -- Subordinate Interface 
    sCyc_i       : in  std_logic ; 
    sLock_i      : in  std_logic ; 
    sStb_i       : in  std_logic ; 
    sWe_i        : in  std_logic ; 
    sAck_o       : out std_logic ; 
    sErr_o       : out std_logic ; 
    sRty_o       : out std_logic ; 
    sStall_o     : out std_logic ; 
    sAdr_i       : in  std_logic_vector ; 
    sDat_o       : out std_logic_vector ; 
    sDat_i       : in  std_logic_vector ; 
    sSel_i       : in  std_logic_vector ; 
    sCti_i       : in  std_logic_vector(2 downto 0) 
  ) ;
end entity WishbonePassThru ;

architecture FeedThru of WishbonePassThru is


begin
  mCyc_o   <= sCyc_i   ;
  mLock_o  <= sLock_i  ;
  mStb_o   <= sStb_i   ;
  mWe_o    <= sWe_i    ;
  sAck_o   <= mAck_i   ;
  sErr_o   <= mErr_i   ;
  sRty_o   <= mRty_i   ;
  sStall_o <= mStall_i ;
  mAdr_o   <= sAdr_i   ;
  mDat_o   <= sDat_i   ;
  sDat_o   <= mDat_i   ;
  mSel_o   <= sSel_i   ;
  mCti_o   <= sCti_i   ;

end architecture FeedThru ;
