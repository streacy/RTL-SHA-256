library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Compression is
port(
      clock       : in std_logic;
      lastBlock   : in boolean;
      M           : in std_logic_vector( 511 downto 0);
      K           : in std_logic_vector(63 downto 0);
		W				: in padded_message_block_array;
      digest      : out std_logic_vector( 255 downto 0 )
    );
end entity;

architecture behaviour of Capstone1 is
  signal H, digest_signal : std_logic_vector( 255 downto 0 ) ;
  signal a, b, c, d, e, f, g, h_signal, T1, T2 : std_logic_vector( 31 downto 0 );
  signal bigS0, bigS1, smallS0, smallS1, maj, ch : std_logic_vector( 31 downto 0 );
  signal compressed : boolean := false;
  signal lastBlock_signal : boolean;
  signal j : integer := 0;
  signal k_signal: std_logic_vector( 63 downto 0);
  signal Message : std_logic_vector(511 downto 0);
    
begin
  sha256_compress: process( clock, lastBlock_signal ) 
    begin			
          if j < 64 then
              maj      <= std_logic_vector((a and b) xor (a and c) xor (b and c));
              ch       <= std_logic_vector((e and f) xor (not(e) and g));
              bigS0    <= std_logic_vector(shift_right(unsigned(a), 2) xor shift_right(unsigned(a), 13) xor shift_right(unsigned(a), 22));
              bigS1    <= std_logic_vector(shift_right(unsigned(e), 6) xor shift_right(unsigned(e), 11) xor shift_right(unsigned(e), 25));
				  T1 		  <= std_logic_vector(unsigned(h)+ unsigned(W(j)) + unsigned(bigS1) + unsigned(ch) + unsigned(k_signal(j)));
              T2 		  <= std_logic_vector(unsigned(maj) + unsigned(bigS0));
              h_signal <= g;
              g <= f;
              f <= e;
              e <=  std_logic_vector(unsigned( d ) + unsigned( T1 ));
              d <= c;
              c <= b;
              b <= a;
              a <= std_logic_vector( unsigned( T1 ) + unsigned( T2 ) );
              j <= j + 1;    
          else
            compressed <= true;
          end if;
        if compressed then
          H( 31 downto 0 ) <= std_logic_vector( unsigned ( H( 31 downto 0 ) ) + unsigned( a ) );
          H( 63 downto 32 ) <= std_logic_vector( unsigned (  H( 63 downto 32 ) ) + unsigned( b ) );
          H( 95 downto 64 ) <= std_logic_vector( unsigned ( H( 95 downto 64 ) ) + unsigned( c ) );
          H( 127 downto 96 ) <= std_logic_vector( unsigned ( H( 127 downto 96 ) ) + unsigned( d ) ); 
          H( 159 downto 128 ) <= std_logic_vector( unsigned( H( 159 downto 128 ) ) + unsigned( e ) );
          H( 191 downto 160 ) <= std_logic_vector( unsigned( H( 191 downto 160 ) ) + unsigned( f ) );
          H( 223 downto 192 ) <= std_logic_vector( unsigned( H( 223 downto 192 ) ) + unsigned( g ) );
          H( 255 downto 224 ) <= std_logic_vector( unsigned( H( 255 downto 224 ) ) + unsigned( h_signal ) );
        end if; 
          
          if lastBlock then
            digest_signal( 31 downto 0 ) <= H( 255 downto 224 );
            digest_signal( 63 downto 32 ) <= H( 223 downto 192 );
            digest_signal( 95 downto 64 ) <= H( 191 downto 160 );
            digest_signal( 127 downto 96 ) <= H( 159 downto 128 );
            digest_signal( 159 downto 128 ) <= H( 159 downto 128 );
            digest_signal( 191 downto 160 ) <= H( 255 downto 224 );
            digest_signal( 223 downto 192 ) <= H( 63 downto 32 );
            digest_signal( 255 downto 224 ) <= H( 31 downto 0 );
            end if;
  end process;

end behaviour;