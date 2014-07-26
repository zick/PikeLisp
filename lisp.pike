int kLPar = '(';
int kRPar = ')';
int kQuote = '\'';

class LObj {
}

class Nil {
  inherit LObj;
}
LObj kNil = Nil();
bool nilp(LObj x) { return _typeof(x) == _typeof(kNil); }

class Num {
  inherit LObj;
  int num;
  void create(int n) { num = n; }
}
LObj kNum = Num(0);
bool nump(LObj x) { return _typeof(x) == _typeof(kNum); }

class Sym {
  inherit LObj;
  string str;
  void create(string s) { str = s; }
}
LObj kSym = Sym("");
bool symp(LObj x) { return _typeof(x) == _typeof(kSym); }

mapping sym_table = (["nil":kNil]);
LObj makeSym(string s) {
  if (!sym_table[s]) {
    sym_table[s] = Sym(s);
  }
  return sym_table[s];
}

class Error {
  inherit LObj;
  string str;
  void create(string s) { str = s; }
}
LObj kError = Error("");
bool errorp(LObj x) { return _typeof(x) == _typeof(kError); }

class Cons {
  inherit LObj;
  LObj car;
  LObj cdr;
  void create(LObj a, LObj d) { car = a; cdr = d; }
}
LObj kCons = Cons(kNil, kNil);
bool consp(LObj x) { return _typeof(x) == _typeof(kCons); }

LObj safeCar(LObj x) {
  if (consp(x)) return x.car;
  return kNil;
}

LObj safeCdr(LObj x) {
  if (consp(x)) return x.cdr;
  return kNil;
}

bool spacep(int c) {
  return c == '\t' || c == '\r' || c == '\n' || c == ' ';
}

bool delimiterp(int c) {
  return c == kLPar || c == kRPar || c == kQuote || spacep(c);
}

string skipSpaces(string s) {
  int i;
  for (i = 0; i < strlen(s); ++i) {
    if (!spacep(s[i])) {
      break;
    }
  }
  return s[i..strlen(s) - 1];
}

LObj makeNumOrSym(string s) {
  int n = (int)s;
  if ((string)n == s) {
    return Num(n);
  }
  return makeSym(s);
}

class ParseState {
  LObj obj;
  string next;
  void create(LObj o, string s) { obj = o; next = s; }
}
ParseState parseError(string s) { return ParseState(Error(s), ""); }

ParseState readAtom(string s) {
  string next = "";
  for (int i = 0; i < strlen(s); ++i) {
    if (delimiterp(s[i])) {
      next = s[i..strlen(s) - 1];
      s = s[0..i - 1];
      break;
    }
  }
  return ParseState(makeNumOrSym(s), next);
}

ParseState read(string s) {
  s = skipSpaces(s);
  if (strlen(s) == 0) {
    return parseError("empty input");
  } else if (s[0] == kRPar) {
    return parseError("invalid syntax: " + s);
  } else if (s[0] == kLPar) {
    return parseError("noimpl");
  } else if (s[0] == kQuote) {
    return parseError("noimpl");
  }
  return readAtom(s);
}

string printObj(LObj obj) {
  if (nilp(obj)) {
    return "nil";
  } else if (nump(obj)) {
    return (string)obj.num;
  } else if (symp(obj)) {
    return obj.str;
  } else if (errorp(obj)) {
    return "<error: " + obj.str + ">";
  } else {
    return "<unknown>";
  }
}

int main()
{
  write("> ");
  while(string line = Stdio.stdin.gets()) {
    LObj o = makeNumOrSym(line);
    ParseState s = read(line);
    write("%s", printObj(s.obj));
    write("\n> ");
  }
}
