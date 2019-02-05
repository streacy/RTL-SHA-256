library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.sha256_datatypes.all;
use work.sha256_constants.all;
use work.sha256_msfunctions.all;

entity CompressionFunction is
port(
      clock 		: in std_logic;
		lastBlock   : in boolean;
		M				: in std_logic_vector(511 downto 0); 
      digest 		: out std_logic_vector( 255 downto 0)
    );
end entity;

architecture behaviour of CompressionFunction is
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
  signal compressed : boolean := false;
  signal schedcomp : boolean := false;
  signal lastB : boolean;
  signal j : integer:= 0;
  signal temp 	: std_logic_vector(511 downto 0):= M; 
  signal schedule : padded_message_block_array;
  signal k		  : integer range 0 to 63;

	
begin

process(clock)
	variable k : integer:=0;
	begin
		if(rising_edge(clock) and clock='1') then
			if k < 16 then						 -- If k < 16 then the message scheduler is the padded input message
				schedule(k) <= temp(31 downto 0);
				temp <= std_logic_vector(shift_right(unsigned(temp),32));
				k := k + 1;
			elsif(k < 64) then									-- Else, W_k = s1(W[k]-2) + W[k]-7 + s0(W[k]-15) + W[k]-16
				schedule(k) <= std_logic_vector(unsigned(s1(schedule(k - 2))) + unsigned(schedule(k - 7)) + unsigned(s0(schedule(k - 15))) + unsigned(schedule(k - 16)));
				k := k + 1;
			else 
				k := 0;
				schedcomp <= true;
			end if;
		end if;	
end process;
	
sha256_compress: process(schedcomp, clock,lastB )	
	variable j : integer:=0;
    begin   
	  if(schedcomp = true)	then
				 if j < 64 then
						sigma1   <= Z1(e);
						ch 	  <= std_logic_vector((e and f) xor (not(e) and g));
						T1 <= std_logic_vector(unsigned(h)+ unsigned(schedule(j)) + unsigned(sigma1) + unsigned(ch) + unsigned(constants(j)));
						sigma0   <= Z0(a);
						maj 	  <= std_logic_vector((a and b) xor (a and c) xor (b and c));
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
						compressed <= true;
				 end if;
			  if compressed then
						 Hdigest( 31 downto 0 ) <= std_logic_vector( unsigned ( Hdigest( 31 downto 0 ) ) + unsigned( a ) );
						 Hdigest( 63 downto 32 ) <= std_logic_vector( unsigned (  Hdigest( 63 downto 32 ) ) + unsigned( b ) );
						 Hdigest( 95 downto 64 ) <= std_logic_vector( unsigned ( Hdigest( 95 downto 64 ) ) + unsigned( c ) );
						 Hdigest( 127 downto 96 ) <= std_logic_vector( unsigned ( Hdigest( 127 downto 96 ) ) + unsigned( d ) ); 
						 Hdigest( 159 downto 128 ) <= std_logic_vector( unsigned( Hdigest( 159 downto 128 ) ) + unsigned( e ) );
						 Hdigest( 191 downto 160 ) <= std_logic_vector( unsigned( Hdigest( 191 downto 160 ) ) + unsigned( f ) );
						 Hdigest( 223 downto 192 ) <= std_logic_vector( unsigned( Hdigest( 223 downto 192 ) ) + unsigned( g ) );
						 Hdigest( 255 downto 224 ) <= std_logic_vector( unsigned( Hdigest( 255 downto 224 ) ) + unsigned( h ) );
			  end if; 
			  
			  if lastBlock then
						digest( 31 downto 0 ) <= Hdigest( 255 downto 224 );
						digest( 63 downto 32 ) <= Hdigest( 223 downto 192 );
						digest( 95 downto 64 ) <= Hdigest( 191 downto 160 );
						digest( 127 downto 96 ) <= Hdigest( 159 downto 128 );
						digest( 159 downto 128 ) <= Hdigest( 159 downto 128 );
						digest( 191 downto 160 ) <= Hdigest( 255 downto 224 );
						digest( 223 downto 192 ) <= Hdigest( 63 downto 32 );
						digest( 255 downto 224 ) <= Hdigest( 31 downto 0 );
				end if;
		end if;
end process sha256_compress;

end architecture behaviour;