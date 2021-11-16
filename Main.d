void azzert (T) (T t)
{
	if (! t)
	{
		import std.stdio;
		
		writef ("Azzertion !\n");
		stdout.flush ();
		assert (0);
	}
}

struct RegexSpec
{
	string _s0;
	string _s1;
	
	string toString () const
	{
		return _s0 ~ "    ^^^^^^^^$$$$$$$$    " ~ _s1;
	}
}

auto Cached_regex (string s0, string s1 = "")
{
	import std.regex;
	static if (1)
		return regex (s0, s1);
	else
	{
		static Regex ! char [RegexSpec] a;
		
		auto spec = RegexSpec (s0, s1);
		
		Regex ! char *pRegex = spec in a;
		if (! pRegex)
		{
			a [spec] = regex (s0, s1);
			pRegex = spec in a;
		}
		
		azzert (pRegex);
		return *pRegex;
	}
}

import std.stdio: File;
struct FileEx
{
	File _file;
	string _sBaseName;
	ulong _cbExpected = -1;
	ulong _cbObtained;
	ulong _iLineInFile;
	
	string toString () const
	{
		import std.format;
		
		immutable string s_cbExpected = _cbExpected + 1 ? format ("%Xh", _cbExpected) : "? ";
		
		return format
		(
			"FileEx (%-48s, %8Xh of %9s)",
			"\"" ~ _sBaseName ~ "\"",
			_cbObtained, s_cbExpected
		);
	}
}

FileEx [string] aFiles;

void ProcessLine (const (char) [] sLine)
{
	import std.stdio;
	import std.regex;
	import std.range;
	import std.array;
	//import std.algorithm;
	import std.conv;
	import std.container.array;
	
	size_t diField = 13;
	do
	{
		if (sLine.empty || sLine.back != ']')
			break;
		
		import std.algorithm.searching: find;
		const (char) [] sLine1 = sLine.find ('[');
		if (sLine1.empty)
			break;
		
		sLine = sLine1;
		sLine.popBack ();
		diField = 0;
	} while (0);
	
	writef ("sLine %s\n{\n", sLine);
	auto rsFields = splitter (sLine, regex (r" "));
	
	string sKey;
	//string sPathName;
	ulong iLineInFile;
	Array ! ubyte abLine; { abLine.reserve (0x400); }
	FileEx *pFileEx;
	
	uint iState;
	size_t iField = -1;
	foreach (sField; rsFields)
	{
		++iField;
		if (iField < diField) continue;
		immutable size_t jField = iField - diField;
		if (1) { if (jField) writef (" "); if (1) writef ("<%s>", sField); }
		
		if (! iState)
		{
			if (! jField)
			{
				if (! sField.empty && sField.front == '[')
					sField.popFront ();
				
				//writef ("%s\n", sField);
				
				if (sField == "FLST")
					iState = 100;
				else
				if (sField == "FLDA")
					iState = 200;
				else
				if (sField == "FLFI")
					iState = 300;
				else
					break;
			}
			else
				azzert (0);
		}
		else
		if (iState == 100)
		{
			if (! jField)
				azzert (1);
			else
			if (jField == 1)
			{
				azzert (sKey.empty);
				sKey = sField.idup;
				azzert (sKey ! in aFiles);
			}
			else
			if (jField == 2)
			{
				azzert (! sKey.empty);
				
				immutable string sPathName = sField.idup;
				//writef ("[%s %s]\n{\n", sKey, sPathName);
				
				auto file = File (sPathName, "wb");
				azzert (file.isOpen);
				azzert (file.name == sPathName);
				
				auto fileex = FileEx (file);
				aFiles [sKey] = fileex;
			}
			else
			if (jField == 3)
			{
				azzert (! sKey.empty);
				
				pFileEx = sKey in aFiles;
				azzert (pFileEx);
				
				auto iValue = parse ! ulong (sField);
				pFileEx._cbExpected = iValue;
				
				writef ("[%s %s %8Xh]\n", sKey, pFileEx._file.name, pFileEx._cbExpected);
			}
			else
				{}
		}
		else
		if (iState == 200)
		{
			if (sKey.empty)
				break;
			
			if (! jField)
				azzert (0);
			else
			if (jField == 1)
			{
				azzert (sKey.empty);
				sKey = sField.idup;
				pFileEx = sKey in aFiles;
				azzert (pFileEx);
			}
			else
			if (jField == 2)
			{
				iLineInFile = parse ! ulong (sField);
				//writef (" %4Xh versus %4Xh:", iLineInFile, pFileEx._iLineInFile);
				azzert (iLineInFile == pFileEx._iLineInFile + 1);
			}
			else
			if (sField == "FLDA")
			{
				pFileEx._file.rawWrite ((&abLine [0]) [0 .. abLine.length]);
				//azzert (abResult.length <= abLine.length);
				writef (".");
				stdout.flush;
				
		                pFileEx._iLineInFile = iLineInFile;
				iState = 299;
			}
			else
			{
				auto iValue = parse ! ubyte (sField, 16);
				abLine.insertBack (iValue);
				//writef (" %02Xh", iValue);
				//writef (".");
			}
		}
		else
		if (iState == 299)
			azzert (0);
		else
		if (iState == 300)
		{
			if (sKey.empty)
				break;
			
			if (! jField)
				azzert (1);
			else
				{}
		}
		else
			azzert (0);
	}
	
	writef ("}\n\n");
}

bool ProcessLine_V2 (ulong iLine, const (char) [] sLine)
{
	import std.format;
	immutable string sPrefix = format ("#%8u: ", iLine);
	
	enum _iDebug = 1;
	static if (_iDebug) import std.stdio;
	
	if (1)       if (_iDebug >= 2) writef ("sLine %s\n{\n", sLine);
	scope (exit) if (_iDebug >= 2) writef ("}\n\n", sLine);
	
	do
	{
	import std.regex;
	
	const (char) [] sPayload;
	
	// [2021-11-14]
	static if (0)
	{
		const auto c0 = sLine.matchFirst (Cached_regex (r"^ \s* (.*?) \s* \[ \s* (.*) \s* \] \s* $", "ix"));
		if (c0)
			sPayload = c0 [2];
	}
	else
	{
		import std.range.primitives;
		
		if (sLine.empty)
			break;
		
		if (sLine.back != ']')
		{
			writef ("%s" ~ "Non-empty line not ending with right-bracket !\n", sPrefix);
			break;
		}
		
		sLine.popBack ();
		
		import std.algorithm.searching;
		sPayload = sLine.find ('[');
		{
			if (! sPayload.empty)
				sPayload.popFront ();
		}
	}
	
	// [2021-11-14]
	//if (c0)
	{
		// [2021-11-14]
		//if (_iDebug >= 4) writef ("Aha: %s\n", c0 [1]);
		//if (_iDebug >= 4) writef ("Aha: %s\n", c0 [2]);
		//
		//const auto sPayload = c0 [2];
		
		import std.array;
		auto rsFields = sPayload.splitter (regex (r" ")).array;
		if (_iDebug >= 5) writef ("%s" ~ "rsFields %s.\n", sPrefix, rsFields);
		
		// [2021-11-14] Speed:
		//if (const auto cPayload = sPayload.matchFirst (Cached_regex (r"^FLST \s+ (\d+) \s+ (\S+) \s+ (\d+) \s+ (.*) \s+ (\d+) \s+ (\d+) \s+ FLST$", "x")))
		if (rsFields [0] == "FLST")
		{
			// [2021-11-14] Speed:
			//immutable string sKey = cPayload [1].idup;
			const auto sKey = rsFields [1];
			
			if (sKey in aFiles)
			{
				writef ("%s" ~ "FLST: Duplicate key %s !\n", sPrefix, sKey);
				return false;
			}
			
			// [2021-11-14] Speed:
			//immutable string sPathName = cPayload [2].idup;
			const auto sPathName = rsFields [2];
			
			string sBaseName;
			{
				if (const auto cBaseName = sPathName.matchFirst (Cached_regex (r"([^/\\]+)$", "ix")))
					sBaseName = cBaseName [1].idup;
				else
					azzert (0);
			}
			
			ulong cbExpected;
			{
				// [2021-11-14] Speed:
				//string s = cPayload [3].idup;
				string s = rsFields [3].idup;
				
				import std.conv;
				cbExpected = parse ! ulong (s);
			}
			
			immutable string sFolderName = "ExtractedFilez";
			
			import std.file;
			mkdirRecurse (sFolderName);
			
			immutable string Final_sPathName = sFolderName ~ "/" ~ sBaseName;
			auto file = File (Final_sPathName, "wb");
			if (! file.isOpen)
			{
				writef ("%s" ~ "FLST: We have failed to open \"%s\" !\n", sPrefix, Final_sPathName);
				return false;
			}
			
			auto fileex = FileEx (file, sBaseName, cbExpected);
			
			if (_iDebug) writef ("%s" ~ "FLST: %16s => %s.\n", sPrefix, sKey, fileex);
			
			aFiles [sKey] = fileex;
		}
		else
		// [2021-11-14] Speed:
		//if (const auto cPayload = sPayload.matchFirst (Cached_regex (r"^FLDA \s+ (\d+) \s+ (\d+) \s* ([0-9A-Fa-f']+) \s* FLDA$", "x")))
		if (rsFields [0] == "FLDA")
		{
			// [2021-11-14] Speed:
			//immutable string sKey = cPayload [1].idup;
			const auto sKey = rsFields [1];
			
			FileEx *pFileEx = sKey in aFiles;
			if (! pFileEx)
			{
				writef ("%s" ~ "FLDA: FLDA without FLST for key %16s !\n", sPrefix, sKey);
				aFiles [sKey] = FileEx (File (), "xxx", -1);
				break;
			}
			
			if (! (pFileEx._cbExpected + 1))
				break;
			
			// [2021-11-14] Speed:
			//string siLineInFile = cPayload [2].idup;
			auto siLineInFile = rsFields [2].idup;
			
			import std.conv;
			immutable ulong iLineInFile = parse ! ulong (siLineInFile, 10);
			if (iLineInFile != pFileEx._iLineInFile + 1)
			{
				writef ("%s" ~ "FLDA: Wrong line in file (%u instead of %u) !\n", sPrefix, iLineInFile, pFileEx._iLineInFile + 1);
				return false;
			}
			
			if (_iDebug >= 3) writef ("FLDA %s %4Xh.\n", sKey, iLineInFile);
			
			if (1)
			{
				import std.container.array;
				Array ! ubyte ab;
				{
					ab.reserve (0x1000);
				}
				
				// [2021-11-14] Speed:
				//auto sAllBytes = cPayload [3].idup;
				auto sAllBytes = rsFields [3];
				
				//auto rsBytes = splitter (sAllBytes, Cached_regex (r"[ ']"));
				import std.array: split;
				auto rsBytes = split (sAllBytes.idup, '\'');
				
				foreach (sByte; rsBytes)
				{
					if (_iDebug >= 4) writef ("_%s", sByte);
					
					if (sByte.length != 2)
					{
						writef ("%s" ~ "FLDA: Bad byte: %s !\n", sPrefix, sByte);
						return false;
					}
					
					// [2021-11-14] Speed:
					immutable ubyte b = parse ! ubyte (sByte, 16);
					//immutable ubyte b = 0xCC;
					
					if (_iDebug >= 3) writef ("=%02Xh", b);
					ab.insertBack (b);
				}
				
				if (_iDebug >= 3) writef ("\n");
				
				if (1) pFileEx._file.rawWrite ((&ab [0]) [0 .. ab.length]);
				pFileEx._cbObtained += ab.length;
			}
			
			pFileEx._iLineInFile = iLineInFile;
		}
		else
		// [2021-11-14] Speed:
		//if (const auto cPayload = sPayload.matchFirst (Cached_regex (r"^FLFI \s* (\d+) \s* FLFI$", "x")))
		if (rsFields [0] == "FLFI")
		{
			// [2021-11-14] Speed:
			//immutable string sKey = cPayload [1].idup;
			immutable string sKey = rsFields [1].idup;
			
			FileEx *pFileEx = sKey in aFiles;
			if (! pFileEx || ! (pFileEx._cbExpected + 1))
			{
				writef ("%s" ~ "FLFI: FLFI without FLST for key %16s !\n", sPrefix, sKey);
				break;
			}
			
			if (_iDebug) writef ("%s" ~ "FLFI: %16s => %s%s\n", sPrefix, sKey, *pFileEx, pFileEx._cbObtained != pFileEx._cbExpected ? " - Warning !" : ".");
			
			pFileEx._file.close ();
		}
		else
		{
			if (_iDebug) writef ("%s" ~ "Unknown !\n", sPrefix);
		}
	}
	} while (0);
	
	return true;
}

ulong GetTime_ms ()
{
	import core.time;
	return MonoTime.currTime.ticks.ticksToNSecs / 1_000_000;
}

void PrintBenchmark (ulong t0, ulong iLine)
{
	import std.stdio;
	
	immutable auto dt = GetTime_ms () - t0;
	writef ("#%8u: dt %8u, speed %8.3f...\n", iLine, dt, cast (double) iLine / dt);
	stdout.flush ();
}

int main ()
{
	import std.range;
	import std.algorithm.iteration;
	import std.stdio;
	
	// [2021-11-14] TODO: How to use Component-Based-Programming ?
	//stdin.byLineCopy.take (size_t (-1)).each ! ProcessLine_V2;
	
	immutable auto t0 = GetTime_ms ();
	ulong iLine = 0;
	foreach (sLine; stdin.byLineCopy.take (size_t (-1)))
	{
		++iLine;
		if (! (iLine % 1000)) PrintBenchmark (t0, iLine);
		
		immutable bool bResult = ProcessLine_V2 (iLine, sLine);
		if (! bResult)
		{
			writef ("#%8u: Error !\n", iLine);
			stdout.flush ();
			break;
		}
	}
	PrintBenchmark (t0, iLine);
	
	{
		if (1)       writef ("Remaining files:\n{\n");
		scope (exit) writef ("}\n\n");
		
		foreach (sKey, ref const fileex; aFiles)
		{
			writef ("%16s => %s%s\n", sKey, fileex, fileex._cbObtained != fileex._cbExpected ? " - Warning !" : ".");
		}
	}
	
	//writef ("\n\n");
	//writef ("Hello, World !\n");
	
	return 0;
}
