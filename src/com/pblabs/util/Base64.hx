package com.pblabs.util;

class Base64
{
	static var b64e :Array<String> = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 
                       'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 
                       'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 
                       'U', 'V', 'W', 'X', 'Y', 'Z', 
                       'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 
                       'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 
                       'u', 'v', 'w', 'x', 'y', 'z', 
                       '+', '/'];

	static var b64d :Array<Int> = [	000,000,000,000,000,000,000,000,000,000,
								   000,000,000,000,000,000,000,000,000,000,
								   000,000,000,000,000,000,000,000,000,000,
								   000,000,000,000,000,000,000,000,000,000,
								   000,000,000,062,000,000,000,063,000,001,
								   002,003,004,005,006,007,008,009,000,000,
								   000,000,000,000,000,010,011,012,013,014,
								   015,016,017,018,019,020,021,022,023,024,
								   025,026,027,028,029,030,031,032,033,034,
								   035,000,000,000,000,000,000,036,037,038,
								   039,040,041,042,043,044,045,046,047,048,
								   049,050,051,052,053,054,055,056,057,058,
								   059,060,061,000,000,000,000,000,000,000, 
								   000,000,000,000,000,000,000,000,000,000,
								   000,000,000,000,000,000,000,000,000,000,
								   000,000,000,000,000,000,000,000,000,000,
								   000,000,000,000,000,000,000,000,000,000,
								   000,000,000,000,000,000,000,000,000,000,
								   000,000,000,000,000,000,000,000,000,000, 
								   000,000,000,000,000,000,000,000,000,000,
								   000,000,000,000,000,000,000,000,000,000,
								   000,000,000,000,000,000,000,000,000,000, 
								   000,000,000,000,000,000,000,000,000,000,
								   000,000,000,000,000,000,000,000,000,000,
								   000,000,000,000,000,000,000,000,000,000, 
								   000,000,000,000,000,000];				

	public static function b64ConvertInt(value :Int, length :Int ) :String 
	{
		// length should be between 1 and 5 only
		if (length == 5)
		{
			var c = new Array<String>();
			c[0] = b64e[(value & 1056964608) >> 24];
			c[1] = b64e[(value & 16515072) >> 18];
			c[2] = b64e[(value & 258048) >> 12];
			c[3] = b64e[(value & 4032) >> 06];
			c[4] = b64e[(value & 63)];
			return c.join("");
		}
		else if (length == 4)
		{
			var c = new Array<String>();
			c[0] = b64e[(value & 16515072) >> 18];
			c[1] = b64e[(value & 258048) >> 12];
			c[2] = b64e[(value & 4032) >> 06];
			c[3] = b64e[(value & 63)];
			return c.join("");
		}
		else if (length == 3)
		{
			var c = new Array<String>();
			c[0] = b64e[(value & 258048) >> 12];
			c[1] = b64e[(value & 4032) >> 06];
			c[2] = b64e[(value & 63)];
			return c.join("");
		}
		else if (length == 2)
		{
			var c = new Array<String>();
			c[0] = b64e[(value & 4032) >> 06];
			c[1] = b64e[(value & 63)];
			return c.join("");
		}
		else
		{
			return b64e[(value & 63)];
		}
	}

	// public static int b64ConvertString(string s) 
	// { // string s should be between 1 and 5 character long only

	// 	int n = s.Length;
	// 	char[] c = s.ToCharArray();
	// 	if (n == 5)
	// 	{
	// 		return (b64d[c[0]] << 24) + (b64d[c[1]] << 18) + 
	// 			   (b64d[c[2]] << 12) + (b64d[c[3]] << 6) + b64d[c[4]];
	// 	}
	// 	else if (n == 4)
	// 	{
	// 		return (b64d[c[0]] << 18) + (b64d[c[1]] << 12) + 
	// 			   (b64d[c[2]] << 6) + b64d[c[3]];
	// 	}
	// 	else if (n == 3)
	// 	{
	// 		return (b64d[c[0]] << 12) + (b64d[c[1]] << 6) + b64d[c[2]];
	// 	}
	// 	else if (n == 2)
	// 	{
	// 		return (b64d[c[0]] << 6) + b64d[c[1]];
	// 	}
	// 	else if (n == 1)
	// 	{
	// 		return b64d[c[0]];
	// 	}

	// 	return 0;
	// }
// }

}
