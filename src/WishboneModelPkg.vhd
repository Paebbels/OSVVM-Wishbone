--
--  File Name:         Axi4ModelPkg.vhd
--  Design Unit Name:  Axi4ModelPkg
--  Revision:          OSVVM MODELS STANDARD VERSION
--
--  Maintainer:        Jim Lewis      email:  jim@synthworks.com
--  Contributor(s):
--     Jim Lewis      jim@synthworks.com
--
--
--  Description:
--      Defines procedures to support Valid and Ready handshaking
--      
--
--  Developed by:
--        SynthWorks Design Inc.
--        VHDL Training Classes
--        http://www.SynthWorks.com
--
--  Revision History:
--    Date      Version    Description
--    03/2022   2022.03    Removed deprecated items
--    01/2020   2020.01    Updated license notice
--    09/2017   2017       Initial revision
--
--
--  This file is part of OSVVM.
--  
--  Copyright (c) 2017 - 2020 by SynthWorks Design Inc.  
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
    
use work.WishboneInterfacePkg.all ; 
  
package WishboneModelPkg is 

  ------------------------------------------------------------
  function CountDontCare (
  ------------------------------------------------------------
    A : std_logic_vector
  ) return integer ; 

  ------------------------------------------------------------
  function CalculateBurstLen(
  ------------------------------------------------------------
    constant NumBytes           : In  integer ; 
    constant ByteAddress        : In  integer ; 
    constant BytesInInterface   : In  integer 
  ) return integer ;

  ------------------------------------------------------------
  procedure CalculateBurstLen (
  ------------------------------------------------------------
    variable TransfersInBurst   : Out  integer ; 
    variable BytesToSend        : Out  integer ; 
    constant BurstFifoMode      : In   integer ;
    constant ItemsInFifo        : In   integer ;
    constant ByteAddr           : In   integer ; 
    constant BytesInInterface   : In   integer
  ) ;

    ------------------------------------------------------------
  function CalculateWriteStrobe (
  ------------------------------------------------------------
    constant ByteAddr         : In  integer ;
    constant BytesInTransfer  : In  integer ; 
    constant BytesInInterface : In  integer 
  ) return std_logic_vector ; 

  ------------------------------------------------------------
  function CalculateWriteStrobe (
  ------------------------------------------------------------
    constant Data          : In  std_logic_vector 
  ) return std_logic_vector ;

  ------------------------------------------------------------
  function AlignBytesToDataBus (
  -- Shift Data to Align it. 
  ------------------------------------------------------------
    constant Data          : In    std_logic_vector ;
    constant DataWidth     : In    integer ;
    constant ByteAddr      : In    integer 
  ) return std_logic_vector ; 

  ------------------------------------------------------------
  function AlignDataBusToBytes (
    -- Shift Data Right and MASK unused bytes. 
    ------------------------------------------------------------
      constant Data          : In    std_logic_vector ;
      constant DataWidth     : In    integer ;
      constant ByteAddr      : In    integer 
    ) return std_logic_vector ;
          
  ------------------------------------------------------------
  procedure FilterUndrivenData (
  ------------------------------------------------------------
    variable Data          : InOut std_logic_vector ;
    variable Strb          : In    std_logic_vector ;
    constant DefaultData   : In    std_logic 
  ) ;

  ------------------------------------------------------------
  procedure CheckDataIsBytes (
  -- Check AXI Write Data Width - BYTE and < WordWidth adjusted for ByteAddr 
  ------------------------------------------------------------
    constant ModelID         : In    AlertLogIDType ; 
    constant DataWidth       : In    integer ;
    constant MessagePrefix   : In    string  := "" ; 
    constant TransferNumber  : In    integer := -1
  ) ; 
  
  ------------------------------------------------------------
  procedure CheckDataWidth (
    -- Check Data Width - BYTE and < WordWidth adjusted for ByteAddr 
    ------------------------------------------------------------
    constant AlertLogID      : In    AlertLogIDType ;
    constant TransRec        : In    AddressBusRecType ; 
    constant ByteAddr        : In    integer ;
    constant DataWidth       : In    integer 
  ) ;

  ------------------------------------------------------------
  procedure PopWriteBurstData (
  ------------------------------------------------------------
    constant WriteBurstFifo  : In    osvvm.ScoreboardPkg_slv.ScoreboardIdType ;
    constant BurstFifoMode   : In    AddressBusFifoBurstModeType ;
    variable WriteData       : InOut std_logic_vector ;
--!!    variable WriteStrb       : InOut std_logic_vector ;
    variable BytesToSend     : InOut integer ; 
    constant ByteAddress     : In    integer := 0 
  ) ;

  ------------------------------------------------------------
  procedure PushReadBurstData (
  -- Push Burst Data into Byte Burst FIFO.   
  ------------------------------------------------------------
    constant ReadBurstFifo  : In    osvvm.ScoreboardPkg_slv.ScoreboardIdType ;
    constant BurstFifoMode  : In    AddressBusFifoBurstModeType ;
    variable ReadData       : InOut std_logic_vector ;
    variable BytesToReceive : InOut integer ; 
    constant ByteAddress    : In    integer := 0 
  ) ;

  
end package WishboneModelPkg ;

-- /////////////////////////////////////////////////////////////////////////////////////////
-- /////////////////////////////////////////////////////////////////////////////////////////

package body WishboneModelPkg is
 
  ------------------------------------------------------------
  function CountDontCare (
  ------------------------------------------------------------
    A : std_logic_vector
  ) return integer is 
    variable result : integer := 0 ; 
  begin
    for i in A'reverse_range loop 
      exit when A(i) /= '-' ; 
      result := result + 1 ; 
    end loop ; 
    return result ; 
  end function CountDontCare ; 

  ------------------------------------------------------------
  function CalculateBurstLen (
  ------------------------------------------------------------
    constant NumBytes           : In  integer ; 
    constant ByteAddress        : In  integer ; 
    constant BytesInInterface   : In  integer 
  ) return integer is
    variable BytesInFirstTransfer : integer ; 
    variable BytesAfterFirstTransfer : integer ; 
  begin
    BytesInFirstTransfer := BytesInInterface - ByteAddress ; 
    if BytesInFirsttransfer  > NumBytes then
      return 0 ; -- only one word in transfer
    else
      BytesAfterFirstTransfer := NumBytes - BytesInFirstTransfer ;
      return 0 + integer(ceil(real(BytesAfterFirstTransfer)/real(BytesInInterface))) ; 
    end if ; 
  end function CalculateBurstLen ; 

  ------------------------------------------------------------
  procedure CalculateBurstLen (
  ------------------------------------------------------------
    variable TransfersInBurst   : Out  integer ; 
    variable BytesToSend        : Out  integer ; 
    constant BurstFifoMode      : In   integer ;
    constant ItemsInFifo        : In   integer ;
    constant ByteAddr           : In   integer ; 
    constant BytesInInterface   : In   integer
  ) is
  begin
    if BurstFifoMode = ADDRESS_BUS_BURST_BYTE_MODE then 
      BytesToSend       := ItemsInFifo ;
      TransfersInBurst  := 1 + CalculateBurstLen(BytesToSend, ByteAddr, BytesInInterface) ;
    else
      BytesToSend       := -1 ; 
      TransfersInBurst  := ItemsInFifo ;
    end if ; 
  end procedure CalculateBurstLen ; 

  ------------------------------------------------------------
  function CalculateWriteStrobe (
  ------------------------------------------------------------
    constant ByteAddr         : In  integer ;
    constant BytesInTransfer  : In  integer ; 
    constant BytesInInterface : In  integer 
  ) return std_logic_vector is
    variable WriteStrobe   : std_logic_vector(BytesInInterface downto 1) := (others => '0') ; 
  begin
    -- Calculate Initial WriteStrobe based on number of bytes
    WriteStrobe(BytesInTransfer downto 1) := (others => '1') ;
        
    -- Adjust WriteStrobe for Address
    -- replace by sll? WriteStrobe sll ByteAddr 
    return WriteStrobe(BytesInInterface - ByteAddr downto 1) & (ByteAddr downto 1 => '0') ;
  end function CalculateWriteStrobe ; 
  
  ------------------------------------------------------------
  function CalculateWriteStrobe (
  ------------------------------------------------------------
    constant Data          : In  std_logic_vector 
  ) return std_logic_vector is
    variable WriteStrobe : std_logic_vector(Data'length/8-1 downto 0) := (others => '0') ; 
    alias aData : std_logic_vector(Data'length-1 downto 0) is Data ; 
  begin
    for i in WriteStrobe'reverse_range loop
      if aData(i*8) /= 'U' then 
        WriteStrobe(i) := '1' ;
      end if ; 
    end loop ;
    return WriteStrobe ;
  end function CalculateWriteStrobe ; 
  
  ------------------------------------------------------------
  function AlignBytesToDataBus (
  ------------------------------------------------------------
    constant Data          : In    std_logic_vector ;
    constant DataWidth     : In    integer ;
    constant ByteAddr      : In    integer 
  ) return std_logic_vector is
    constant DATA_LEFT : integer := Data'length-1 ; 
    alias    aData     : std_logic_vector(DATA_LEFT downto 0) is Data ; 
    variable result    : std_logic_vector(DATA_LEFT downto 0) := (others => 'U') ; 
  begin
    if DataWidth < Data'length then   
      Result(DataWidth + ByteAddr*8 - 1 downto ByteAddr*8) := aData(DataWidth-1 downto 0) ;
      return Result ; 
    else 
      -- Make Bits to the Right of ByteAddr a U
      Result(DATA_LEFT downto ByteAddr*8) := aData(DATA_LEFT downto ByteAddr*8) ; 
      return Result ; 
    end if ; 
  end function AlignBytesToDataBus ; 
  
  ------------------------------------------------------------
  function AlignDataBusToBytes (
  -- Shift Data Right and MASK unused bytes. 
  ------------------------------------------------------------
    constant Data          : In    std_logic_vector ;
    constant DataWidth     : In    integer ;
    constant ByteAddr      : In    integer 
  ) return std_logic_vector is
    constant DATA_LEFT : integer := Data'length-1 ; 
    alias    aData         : std_logic_vector(DATA_LEFT downto 0) is Data ; 
    variable Result        : std_logic_vector(DATA_LEFT downto 0) := (others => '0') ; 
  begin
    if DataWidth < Data'length then  
      Result(DataWidth-1 downto 0) := aData(DataWidth + ByteAddr*8 - 1 downto ByteAddr*8) ;    
      return Result ; 
    else
      -- Make Bits to the Right of ByteAddr a 0
      Result(DATA_LEFT downto ByteAddr*8) := aData(DATA_LEFT downto ByteAddr*8) ; 
      return Result ; 
    end if ; 
  end function AlignDataBusToBytes ; 

  ------------------------------------------------------------
  procedure FilterUndrivenData (
  ------------------------------------------------------------
    variable Data          : InOut std_logic_vector ;
    variable Strb          : In    std_logic_vector ;
    constant DefaultData   : In    std_logic 
  ) is
    alias aData : std_logic_vector(Data'length-1 downto 0) is Data ; 
    alias aStrb : std_logic_vector(Strb'length-1 downto 0) is Strb ; 
  begin
    for i in aStrb'range loop
      if aStrb(i) = '0' then 
        aData(i*8+7 downto i*8) := (others => DefaultData) ;
      end if ; 
    end loop ; 
  end procedure FilterUndrivenData ; 
  
  ------------------------------------------------------------
  procedure CheckDataIsBytes (
  -- Check that DataWidth is byte oriented
  ------------------------------------------------------------
    constant ModelID         : In    AlertLogIDType ; 
    constant DataWidth       : In    integer ;
    constant MessagePrefix   : In    string  := "" ; 
    constant TransferNumber  : In    integer := -1
  ) is
  begin
    if DataWidth mod 8 /= 0 then 
      if TransferNumber > 0 then 
        Alert(ModelID, 
          MessagePrefix  &
          "Data not on a byte boundary." & 
          "  DataWidth: " & to_string(DataWidth) & 
          "  TransferNumber: " & to_string(TransferNumber), 
          FAILURE) ;
      else
        Alert(ModelID, 
          MessagePrefix  &
          "Data not on a byte boundary." & 
          "  DataWidth: " & to_string(DataWidth) , 
          FAILURE) ;
      end if ; 
    end if ; 
  end procedure CheckDataIsBytes ; 
  
  ------------------------------------------------------------
  procedure CheckDataWidth (
  -- Check Data Width - BYTE and < WordWidth adjusted for ByteAddr 
  ------------------------------------------------------------
    constant AlertLogID      : In    AlertLogIDType ;
    constant TransRec        : In    AddressBusRecType ; 
    constant ByteAddr        : In    integer ;
    constant DataWidth       : In    integer 
  ) is
    alias RecDataWidth is TransRec.DataWidth ; 
    alias RecOperationNum is TransRec.Rdy ; 
  begin
    if DataWidth mod 8 /= 0 then 
      Alert(AlertLogID, 
      "Transaction Data not on a byte boundary." & 
      "  Data Width: " & to_string(RecDataWidth) & 
      "  Operation # " & to_string(RecOperationNum), 
      FAILURE) ;
    end if ;
    if RecDataWidth + ByteAddr*8 > DataWidth and RecDataWidth /= DataWidth then
      Alert(AlertLogID, 
        "Transaction Data Width too large." & 
        "  ByteAddr: " & to_string(ByteAddr) & " * 8" & 
        "  + Transaction Data Width: " & to_string(RecDataWidth) & 
        "  > Interface Data Width: " & to_string(DataWidth) & 
        "  Operation # " & to_string(RecOperationNum),
        FAILURE) ;
    end if ; 
  end procedure CheckDataWidth ; 

  ------------------------------------------------------------
  -- Local
  procedure PopWriteBurstByteData (
  ------------------------------------------------------------
    constant WriteBurstFifo  : In    osvvm.ScoreboardPkg_slv.ScoreboardIdType ;
    variable WriteData       : InOut std_logic_vector ;
--!!    variable WriteStrb       : InOut std_logic_vector ;
    variable BytesToSend     : InOut integer ; 
    constant ByteAddress     : In    integer := 0 
  ) is
    constant DataLeft : integer := WriteData'length-1; 
    alias aWriteData : std_logic_vector(DataLeft downto 0) is WriteData ; 
--!!    alias aWriteStrb : std_logic_vector(WriteStrb'length-1 downto 0) is WriteStrb ;
    variable DataIndex    : integer := ByteAddress * 8 ; 
    variable StrbIndex    : integer := ByteAddress ; 
  begin
    aWriteData := (others => 'U') ;
--!!    aWriteStrb := (others => '0') ;
    -- First Byte is put in right side of word
    PopByte : while DataIndex <= DataLeft loop  
      aWriteData(DataIndex+7 downto DataIndex) := Pop(WriteBurstFifo) ; 
--!!      if aWriteData(DataIndex) /= 'U' then 
--!!        aWriteStrb(StrbIndex) := '1' ; 
--!!      end if ; 
      BytesToSend := BytesToSend - 1 ; 
      exit when BytesToSend = 0 ; 
      DataIndex := DataIndex + 8 ; 
      StrbIndex := StrbIndex + 1 ; 
    end loop PopByte ;
  end procedure PopWriteBurstByteData ; 

  ------------------------------------------------------------
  -- Local
  procedure PopWriteBurstWordData (
  ------------------------------------------------------------
    constant WriteBurstFifo  : In    osvvm.ScoreboardPkg_slv.ScoreboardIdType ;
    variable WriteData       : InOut std_logic_vector ;
--!!    variable WriteStrb       : InOut std_logic_vector ;
    constant ByteAddress     : In    integer := 0 
  ) is
    alias aWriteData : std_logic_vector(WriteData'length-1 downto 0) is WriteData ; 
--!!    alias aWriteStrb : std_logic_vector(WriteStrb'length-1 downto 0) is WriteStrb ;
    variable DataIndex    : integer := 0 ; 
  begin
    aWriteData := Pop(WriteBurstFifo) ; 
--!!    aWriteStrb := (others => '0') ; 
    
    for i in 0 to ByteAddress-1 loop 
      aWriteData(DataIndex + 7 downto DataIndex) := (others => 'U') ; 
      DataIndex := DataIndex + 8 ; 
    end loop ; 
    
--!!    for i in ByteAddress to WriteStrb'length-1 loop 
--!!      if aWriteData(DataIndex) /= 'U' then 
--!!        aWriteStrb(i) := '1' ; 
--!!      end if ; 
--!!      DataIndex := DataIndex + 8 ;
--!!    end loop ;
  end procedure PopWriteBurstWordData ; 
  
  ------------------------------------------------------------
  procedure PopWriteBurstData (
  ------------------------------------------------------------
    constant WriteBurstFifo  : In    osvvm.ScoreboardPkg_slv.ScoreboardIdType ;
    constant BurstFifoMode   : In    AddressBusFifoBurstModeType ;
    variable WriteData       : InOut std_logic_vector ;
--!!    variable WriteStrb       : InOut std_logic_vector ;
    variable BytesToSend     : InOut integer ; 
    constant ByteAddress     : In    integer := 0 
  ) is
  begin
    case BurstFifoMode is
      when ADDRESS_BUS_BURST_BYTE_MODE => 
--!!        PopWriteBurstByteData(WriteBurstFifo, WriteData, WriteStrb, BytesToSend, ByteAddress) ;
        PopWriteBurstByteData(WriteBurstFifo, WriteData, BytesToSend, ByteAddress) ;
        
      when ADDRESS_BUS_BURST_WORD_MODE => 
--!!        PopWriteBurstWordData(WriteBurstFifo, WriteData, WriteStrb, ByteAddress) ;
        PopWriteBurstWordData(WriteBurstFifo, WriteData, ByteAddress) ;

      when others => 
        -- Already checked, this should never happen
        Alert("PopWriteBurstData: BurstFifoMode Invalid Mode: " & to_string(BurstFifoMode), FAILURE) ;
        
    end case ; 
  end procedure PopWriteBurstData ; 

  ------------------------------------------------------------
  procedure PushReadBurstByteData (
  -- Push Burst Data into Byte Burst FIFO.   
  ------------------------------------------------------------
    constant ReadBurstFifo  : In    osvvm.ScoreboardPkg_slv.ScoreboardIdType ;
    variable ReadData       : InOut std_logic_vector ;
    variable BytesToReceive : InOut integer ; 
    constant ByteAddress    : In    integer := 0 
  ) is
    constant DataLeft : integer := ReadData'length-1; 
    alias aReadData : std_logic_vector(DataLeft downto 0) is ReadData ; 
    variable DataIndex    : integer := ByteAddress * 8 ; 
    variable StrbIndex    : integer := ByteAddress ; 
  begin
    -- First Byte is put in right side of word
    PushByte : while DataIndex <= DataLeft loop  
      Push(ReadBurstFifo, aReadData(DataIndex+7 downto DataIndex)) ;
      BytesToReceive := BytesToReceive - 1 ; 
      exit when BytesToReceive = 0 ; 
      DataIndex := DataIndex + 8 ; 
    end loop PushByte ;
  end procedure PushReadBurstByteData ; 

  ------------------------------------------------------------
  procedure PushReadBurstData (
  -- Push Burst Data into Byte Burst FIFO.   
  ------------------------------------------------------------
    constant ReadBurstFifo  : In    osvvm.ScoreboardPkg_slv.ScoreboardIdType ;
    constant BurstFifoMode  : In    AddressBusFifoBurstModeType ;
    variable ReadData       : InOut std_logic_vector ;
    variable BytesToReceive : InOut integer ; 
    constant ByteAddress    : In    integer := 0 
  ) is
  begin
    case BurstFifoMode is
      when ADDRESS_BUS_BURST_BYTE_MODE => 
        PushReadBurstByteData(ReadBurstFifo, ReadData, BytesToReceive, ByteAddress) ;
        
      when ADDRESS_BUS_BURST_WORD_MODE => 
        Push(ReadBurstFifo, ReadData) ; 

      when others => 
        -- Already checked, this should never happen
        Alert("PushReadBurstData: BurstFifoMode Invalid Mode: " & to_string(BurstFifoMode), FAILURE) ;
    end case ; 
  end procedure PushReadBurstData ; 

end package body WishboneModelPkg ; 