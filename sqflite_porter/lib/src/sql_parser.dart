bool isWhitespace(int codeUnit) {
  switch (codeUnit) {
    case 9: // \t
    case 10: // \r
    case 13: // \n
    case 32: // space
      return true;
  }
  return false;
}

bool isStringWrapper(int codeUnit) {
  switch (codeUnit) {
    case 39: // '
    case 34: // "
    case 96: // `
      return true;
  }
  return false;
}

bool isSeparator(int codeUnit) {
  switch (codeUnit) {
    case 40: // (
    case 44: // ,
    case 35: // #
    case 41: // )
    case 59: // ;
      return true;
  }
  return false;
}

String unescapeText(String name) {
  if (name.length > 0) {
    var startCodeUnit = name.codeUnitAt(0);
    if (isStringWrapper(startCodeUnit)) {
      if (name.length > 1) {
        var endCodeUnit = name.codeUnitAt(name.length - 1);
        if (endCodeUnit == startCodeUnit) {
          return name.substring(1, name.length - 1);
        } else {
          return name.substring(1);
        }
      }
    }
  }
  return name;
}

class SqlParserIndex {
  int position;

  @override
  String toString() {
    return "pos: $position";
  }
}

class SqlParser {
  SqlParser(this.sql);

  final String sql;
  int position = 0;

  void skipWhitespaces({bool skip, SqlParserIndex index}) {
    int position = index?.position ?? this.position;

    while (true) {
      if (atEnd(position)) {
        break;
      }
      int codeUnit = sql.codeUnitAt(position);
      if (isWhitespace(codeUnit)) {
        position++;
      } else {
        break;
      }
    }
    if (skip == true) {
      this.position = position;
    }
    if (index != null) {
      index.position = position;
    }
  }

  bool atEnd([int position]) {
    return (position ?? this.position) == sql.length;
  }

  String getNextToken({bool skip, SqlParserIndex index}) {
    index ??= SqlParserIndex();
    index.position ??= this.position;
    skipWhitespaces(skip: skip, index: index);
    if (!atEnd(index.position)) {
      var sb = StringBuffer();

      int codeUnit = sql.codeUnitAt(index.position);
      int startCodeUnit;
      if (isStringWrapper(codeUnit)) {
        startCodeUnit = codeUnit;
      }
      sb.writeCharCode(codeUnit);
      index.position++;

      // is separator ?
      bool isTokenSeparator = false;
      if (startCodeUnit == null) {
        if (isSeparator(codeUnit)) {
          isTokenSeparator = true;
        }
      }

      if (!isTokenSeparator) {
        while (true) {
          if (atEnd(index.position)) {
            if (startCodeUnit != null) {
              return null;
            } else {
              break;
            }
          }
          codeUnit = sql.codeUnitAt(index.position);
          if (startCodeUnit != null) {
            sb.writeCharCode(codeUnit);
          } else {
            if (isWhitespace(codeUnit) || isSeparator(codeUnit)) {
              break;
            } else {
              sb.writeCharCode(codeUnit);
            }
          }
          index.position++;
          if (codeUnit == startCodeUnit) {
            break;
          }
        }
      }
      if (skip == true) {
        this.position = index.position;
      }
      return sb.toString();
    } else {
      return null;
    }
  }

  bool parseToken(String token) {
    var index = SqlParserIndex()..position = position;
    var nextToken = getNextToken(index: index);
    if (token.toLowerCase() == nextToken?.toLowerCase()) {
      // skip it
      position = index.position;
      return true;
    }
    return false;
  }

  bool parseTokens(List<String> tokens) {
    var index = SqlParserIndex()..position = position;
    for (var token in tokens) {
      var nextToken = getNextToken(index: index);
      if (token.toLowerCase() != nextToken?.toLowerCase()) {
        return false;
      }
    }
    // skip them
    position = index.position;
    return true;
  }

  String getNextStatement({bool skip, SqlParserIndex index}) {
    skipWhitespaces(skip: skip, index: index);
    index ??= SqlParserIndex()..position = position;
    int startPosition = index.position;
    var sb = StringBuffer();
    String currentTriggerStatement;
    String previousToken;
    while (true) {
      var token = getNextToken(skip: skip, index: index);
      if (token == ';' || token == null) {
        sb.write(sql.substring(startPosition, index.position));

        var statement = sb.toString();

        var statementParser = SqlParser(statement);
        if (currentTriggerStatement != null) {
          currentTriggerStatement += statement;
        } else if (statementParser.parseTokens(['create', 'trigger'])) {
          currentTriggerStatement = statement;
        }

        if (currentTriggerStatement != null) {
          if (previousToken.toLowerCase() == 'end') {
            return currentTriggerStatement;
          }
        } else {
          return statement;
        }
      }

      previousToken = token;
    }
  }
}

List<String> parseStatements(String sql) {
  var allParser = SqlParser(sql);
  var index = SqlParserIndex()..position = allParser.position;
  var statements = <String>[];

  while (true) {
    var statement = allParser.getNextStatement(skip: true, index: index);
    if (statement == '') {
      break;
    }
    statements.add(statement);
  }
  return statements;
  /*
  // Parse a list of statements
  // Special handling for create trigger though...
  var lines = sql.split(';\n');
  var statements = <String>[];

  String currentTriggerStatement;
  for (var line in lines) {
    var parser = SqlParser(line);

    if (currentTriggerStatement == null) {
      if (parser.parseTokens(['create', 'trigger'])) {
        currentTriggerStatement = line;
      } else {
        statements.add(line);
      }
    } else {
      // add it
      currentTriggerStatement += ';\n$line';
      // Should terminate with END
      var trimmed = line.trim();
      if (trimmed.length >= 3 &&
          trimmed.substring(trimmed.length - 3, trimmed.length).toLowerCase() ==
              'end') {
        statements.add(currentTriggerStatement);
        currentTriggerStatement = null;
      }
    }
  }

  return statements;
  */
}
