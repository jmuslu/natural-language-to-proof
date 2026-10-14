-- | Minimal JSON input/output for benchmark JSONL and the scoped parser protocol.
--
-- Written here because the project depends only on @base@ and @containers@.
-- It parses the full JSON grammar (objects, arrays, strings with escapes,
-- numbers, literals); it does not aim to be fast or to report positions well.
module NL2Proof.Bench.JSON
  ( JValue(..)
  , parseJSON
  , renderJSON
  , field
  , str
  , obj
  ) where

import Data.Char (chr, ord, isDigit, isHexDigit, isSpace, digitToInt)
import Data.List (intercalate)
import Numeric (showHex)

data JValue
  = JObj [(String, JValue)]
  | JArr [JValue]
  | JStr String
  | JNum Double
  | JBool Bool
  | JNull
  deriving (Eq, Show)

-- | Serialize one JSON value without embedded record separators. Non-finite
-- machine doubles have no JSON representation and are emitted as null.
renderJSON :: JValue -> String
renderJSON value = case value of
  JObj fields -> "{" ++ intercalate "," [quote key ++ ":" ++ renderJSON v | (key,v) <- fields] ++ "}"
  JArr items -> "[" ++ intercalate "," (map renderJSON items) ++ "]"
  JStr text -> quote text
  JNum numberValue | isNaN numberValue || isInfinite numberValue -> "null"
                   | otherwise -> show numberValue
  JBool True -> "true"
  JBool False -> "false"
  JNull -> "null"
  where
    quote text = "\"" ++ concatMap escape text ++ "\""
    escape '\"' = "\\\""
    escape '\\' = "\\\\"
    escape c
      | ord c < 0x20 = let hex = showHex (ord c) "" in "\\u" ++ replicate (4-length hex) '0' ++ hex
      | otherwise = [c]

parseJSON :: String -> Either String JValue
parseJSON s = case value (skip s) of
  Right (v, rest) | all isSpace rest -> Right v
                  | otherwise        -> Left ("trailing input: " ++ take 20 rest)
  Left e -> Left e

field :: String -> JValue -> Maybe JValue
field k (JObj kvs) = lookup k kvs
field _ _          = Nothing

str :: JValue -> Maybe String
str (JStr s) = Just s
str _        = Nothing

obj :: JValue -> Maybe [(String, JValue)]
obj (JObj kvs) = Just kvs
obj _          = Nothing

type P a = String -> Either String (a, String)

skip :: String -> String
skip = dropWhile isSpace

value :: P JValue
value s = case s of
  '{' : r -> object (skip r)
  '[' : r -> array (skip r)
  '"' : r -> fmap (\(x, r') -> (JStr x, skip r')) (string r)
  't' : 'r' : 'u' : 'e' : r -> Right (JBool True, skip r)
  'f' : 'a' : 'l' : 's' : 'e' : r -> Right (JBool False, skip r)
  'n' : 'u' : 'l' : 'l' : r -> Right (JNull, skip r)
  c : _ | c == '-' || isDigit c -> number s
  _ -> Left ("unexpected: " ++ take 20 s)

object :: P JValue
object ('}' : r) = Right (JObj [], skip r)
object s = go [] s
  where
    go acc ('"' : r) = do
      (k, r1) <- string r
      case skip r1 of
        ':' : r2 -> do
          (v, r3) <- value (skip r2)
          case r3 of
            ',' : r4 -> go ((k, v) : acc) (skip r4)
            '}' : r4 -> Right (JObj (reverse ((k, v) : acc)), skip r4)
            _        -> Left "expected , or } in object"
        _ -> Left "expected : in object"
    go _ r = Left ("expected key: " ++ take 20 r)

array :: P JValue
array (']' : r) = Right (JArr [], skip r)
array s = go [] s
  where
    go acc r = do
      (v, r1) <- value r
      case r1 of
        ',' : r2 -> go (v : acc) (skip r2)
        ']' : r2 -> Right (JArr (reverse (v : acc)), skip r2)
        _        -> Left "expected , or ] in array"

-- | After the opening quote.
string :: P String
string = go []
  where
    go acc ('"' : r) = Right (reverse acc, r)
    go acc ('\\' : c : r) = case c of
      'n' -> go ('\n' : acc) r
      't' -> go ('\t' : acc) r
      'r' -> go ('\r' : acc) r
      'b' -> go ('\b' : acc) r
      'f' -> go ('\f' : acc) r
      'u' | (h, r') <- splitAt 4 r, length h == 4, all isHexDigit h ->
              go (chr (foldl (\a d -> 16 * a + digitToInt d) 0 h) : acc) r'
      _   -> go (c : acc) r
    go acc (c : r) = go (c : acc) r
    go _ [] = Left "unterminated string"

number :: P JValue
number s =
  let (tok, r) = span (\c -> isDigit c || c `elem` "+-.eE") s
  in case reads (fixup tok) :: [(Double, String)] of
       [(d, "")] -> Right (JNum d, skip r)
       _         -> Left ("bad number: " ++ tok)
  where
    -- Haskell's reads rejects a leading '-' only in odd spellings like "-.5";
    -- JSON forbids those anyway, so only a bare trailing '.' needs care.
    fixup t = if not (null t) && last t == '.' then t ++ "0" else t
