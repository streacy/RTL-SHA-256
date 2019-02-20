library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.sha256_datatypes.all;
use work.sha256_constants.all;
use work.sha256_msfunctions.all;
entity CompressionFunction is
port(
clk: IN STD_LOGIC;
clock : IN STD_LOGIC;
reset : IN STD_LOGIC:='0';
ready : IN STD_LOGIC:='0';
readyBlock:IN STD_LOGIC:='0';
--messageBit : OUT std_logic_vector(0 to 511)

blockSet  : in std_logic;
compressdone : out std_logic;
  digest   : out std_logic_vector( 255 downto 0);
  sched   : out std_logic_vector(31 downto 0);
  sched1   : out std_logic_vector(31 downto 0);
  sched32   : out std_logic_vector(31 downto 0);
  sched63   : out std_logic_vector(31 downto 0);
  outmem  : out std_logic_vector(31 downto 0);
  temp1  : out std_logic_vector(31 downto 0);
  addrout   : out std_logic_vector(3 downto 0)
    );
end entity;
architecture behaviour of CompressionFunction is
 constant ss : string :="abc";
 signal output:std_logic_vector(0 to ss'length*8 +(447- ss'length*8) mod 512+64);
 signal message:std_logic_vector(0 to 511);
 signal messageLength : std_LOGIC_VECTOR(0 to 63);
 signal len_unsigned,k0 : unsigned (0 to 63);
 signal nBlocks,x:integer;
 signal messageBit : std_logic_vector(0 to 511);

  signal Hdigest : std_logic_vector( 255 downto 0 );
  signal a : std_logic_vector( 31 downto 0 ):=H0; 
  signal b : std_logic_vector( 31 downto 0 ):=H1;
  signal c : std_logic_vector( 31 downto 0 ):=H2;
  signal d : std_logic_vector( 31 downto 0 ):=H3;
  signal e : std_logic_vector( 31 downto 0 ):=H4;
  signal f : std_logic_vector( 31 downto 0 ):=H5;
  signal g : std_logic_vector( 31 downto 0 ):=H6;
  signal h : std_logic_vector( 31 downto 0 ):=H7;
  signal T1, T2, Sigma0, Sigma1, maj, ch : std_logic_vector( 31 downto 0 );
  signal compressed : std_logic := '0';
  signal lastB : boolean:= false;
  signal j    : integer range 0 to 63;
  signal memaddr  : std_logic_vector(3 downto 0):= "0000";
  signal memout  : std_logic_vector(31 downto 0);
  signal flag  : std_logic:='0';
  signal schedule : padded_message_block_array;
  signal k    : integer range 0 to 63;
  signal rdyBlock : std_logic;
  
  --FSM Signals
  type states is(
 Rdy,
 ScheduleMessage,
 CompressBlock,
 Append
);
 signal current_state : states:=Rdy;
 
 COMPONENT PaddedMessageRegFile IS
 PORT
 (clk : in  STD_LOGIC;
    wen : in  STD_LOGIC;
    addr : in  STD_LOGIC_VECTOR (3 downto 0);
    dataIn : in  STD_LOGIC_VECTOR (31 downto 0);
    dataOut : out  STD_LOGIC_VECTOR (31 downto 0)
 );
 END COMPONENT;

 
begin
 paddedmessage : PaddedMessageRegFile
 PORT MAP(
   clk => clock ,
   wen => '0',
   addr => memaddr,
   dataIn => x"00000000",
   dataOut => memout
 );

 PROCESS(clk,ready,readyBlock,reset)
  begin 
   if(clk'Event and clk='1' and reset='1')then
    output<=std_logic_vector(to_unsigned(0,output'length));
   
   elsif(clk'Event and clk='1' and readyBlock='1'and ready='1')then
    if(x=(nBlocks-1))then
     lastB<=true;
    else
     x<=x+1;
    end if;
    
   elsif(clk'Event and clk='1' and ready ='1')then
   --k<=output'length;
    nBlocks<=output'length/512;
    IF(nBlocks /= 0)then
     x<=0;
    end if;
    --n<=nBlocks;
 
    len_unsigned<=shift_left(to_unsigned(ss'length,64),3);
    messageLength<= std_logic_vector(len_unsigned);
    k0<=(447- len_unsigned) mod 512;   
    output(TO_INTEGER(len_unsigned))<='1';
    for i in 1 to 447 loop
     exit when i=((TO_INTEGER(k0))+1);
     output((TO_INTEGER(len_unsigned)) +i)<='0'; 
    end loop;    
    for i in  ss'range loop
     output((8*i)-8 to (8*i)-1)<=std_logic_vector(to_unsigned(character'pos(ss(i)),8));
    end loop;
    for i in 0 to 63 loop
     output(output'length-64+i)<=messageLength(i);
    end loop;
   end if;
   
  for i in 0 to 511 loop
    message(i)<=output(x*512+i);
  end loop;
  messageBit<=message;
  --outBit<=output;
  --z<=to_integer(k0);
  
  end process;
 
process(clk,lastB, blockSet)
  variable k : integer:=0;
  variable j : integer:=0;
 begin
 if(clock'Event and clock='1')then
  case current_state is
  
   when Rdy =>
    rdyBlock <= '1';
    if (blockSet='1') then
     current_state<=ScheduleMessage;
    else
     current_state<=Rdy;
    end if;
   
   when ScheduleMessage =>
     rdyBlock <= '0';
   
     
     if k < 16 then     -- If k < 16 then the message scheduler is the padded input message
      outmem <=memout;
      addrout <= memaddr;
      schedule(k) <= memout;
      k := k + 1;
      memaddr <= std_logic_vector(unsigned(memaddr) + 1);
     elsif(k < 64) then         -- Else, W_k = s1(W[k]-2) + W[k]-7 + s0(W[k]-15) + W[k]-16
       schedule(k) <= std_logic_vector(unsigned(s1(schedule(k - 2))) + unsigned(schedule(k - 7)) + unsigned(s0(schedule(k - 15))) + unsigned(schedule(k - 16)));
       k := k + 1;
     else
     current_state<=CompressBlock;
     end if;
    
    when CompressBlock =>
     rdyBlock <= '0';
   
        if j < 64 then
         sigma1   <= Z1(e);
         ch    <= std_logic_vector((e and f) xor (not(e) and g));
         T1 <= std_logic_vector(unsigned(h)+ unsigned(schedule(j)) + unsigned(sigma1) + unsigned(ch) + unsigned(constants(j)));
         sigma0   <= Z0(a);
         maj    <= std_logic_vector((a and b) xor (a and c) xor (b and c));
         T2 <= std_logic_vector(unsigned(maj) + unsigned(sigma0));
         
         h <= g;
         g <= f;
         f <= e;
         e <= std_logic_vector( unsigned( d ) + unsigned( T1 ) );
         d <= c;
         c <= b;
         b <= a;
         a <= std_logic_vector( unsigned( T1 ) + unsigned( T2 ) );
         j := j + 1;
        else
         compressed <= '1';
        end if;
        
        if (compressed = '1') then
          Hdigest( 31 downto 0 ) <= std_logic_vector( unsigned ( Hdigest( 31 downto 0 ) ) + unsigned( a ) );
          Hdigest( 63 downto 32 ) <= std_logic_vector( unsigned (  Hdigest( 63 downto 32 ) ) + unsigned( b ) );
          Hdigest( 95 downto 64 ) <= std_logic_vector( unsigned ( Hdigest( 95 downto 64 ) ) + unsigned( c ) );
          Hdigest( 127 downto 96 ) <= std_logic_vector( unsigned ( Hdigest( 127 downto 96 ) ) + unsigned( d ) ); 
          Hdigest( 159 downto 128 ) <= std_logic_vector( unsigned( Hdigest( 159 downto 128 ) ) + unsigned( e ) );
          Hdigest( 191 downto 160 ) <= std_logic_vector( unsigned( Hdigest( 191 downto 160 ) ) + unsigned( f ) );
          Hdigest( 223 downto 192 ) <= std_logic_vector( unsigned( Hdigest( 223 downto 192 ) ) + unsigned( g ) );
          Hdigest( 255 downto 224 ) <= std_logic_vector( unsigned( Hdigest( 255 downto 224 ) ) + unsigned( h ) );
        end if; 
        
        if (lastB = true) then
        current_state<=Append;
        else
        current_state<=Rdy;
        end if;
        
    when Append =>
     rdyBlock <= '0';
     
     digest( 31 downto 0 ) <= Hdigest( 255 downto 224 );
     digest( 63 downto 32 ) <= Hdigest( 223 downto 192 );
     digest( 95 downto 64 ) <= Hdigest( 191 downto 160 );
     digest( 127 downto 96 ) <= Hdigest( 159 downto 128 );
     digest( 159 downto 128 ) <= Hdigest( 159 downto 128 );
     digest( 191 downto 160 ) <= Hdigest( 255 downto 224 );
     digest( 223 downto 192 ) <= Hdigest( 63 downto 32 );
     digest( 255 downto 224 ) <= Hdigest( 31 downto 0 );
     
     current_state<=Rdy;
         
      
 end case;
end if;
 sched <= schedule(0);
 sched1 <= schedule(1);
 sched32 <= schedule(32);
 sched63 <= schedule(63);
 compressdone <= compressed;
 temp1 <= T1;
end process;
end architecture behaviour;