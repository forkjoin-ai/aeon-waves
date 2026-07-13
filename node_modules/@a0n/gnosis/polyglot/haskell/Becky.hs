-- becky.hs -- GG compiler in Haskell.
-- Data.HashMap for O(1) lookup. Lazy evaluation.
-- Run: stack script Becky.hs -- betti.gg --summary
-- Or: runghc Becky.hs betti.gg --summary

module Main where

import qualified Data.Map.Strict as Map
import Data.List (isPrefixOf, isInfixOf, foldl')
import Data.Char (isSpace, isUpper)
import System.Environment (getArgs)
import System.IO (hPutStrLn, stderr)
import System.Exit (exitFailure)
import Data.Time.Clock.System (getSystemTime, systemNanoseconds, systemSeconds)
import Text.Printf (printf)

type Props = Map.Map String String

data GgNode = GgNode { nodeId :: String, nodeLabels :: [String], nodeProps :: Props } deriving Show
data GgEdge = GgEdge { sourceIds :: [String], targetIds :: [String], edgeType :: String, edgeProps :: Props } deriving Show
data GgProgram = GgProgram { nodes :: Map.Map String GgNode, edges :: [GgEdge] } deriving Show

trim :: String -> String
trim = reverse . dropWhile isSpace . reverse . dropWhile isSpace

stripComments :: String -> String
stripComments = unlines . filter (not . null) . map (trim . takeWhile2 (/= "//")) . lines
  where takeWhile2 _ [] = []
        takeWhile2 p (x:xs) = if p [x, head' xs] then x : takeWhile2 p xs else []
        head' [] = ' '
        head' (x:_) = x

-- Simpler: just split on "//"
stripComments' :: String -> String
stripComments' src = unlines $ filter (not . null) $ map processLine (lines src)
  where processLine l = let trimmed = trim $ takeWhile' l in trimmed
        takeWhile' s = case breakOn "//" s of (before, _) -> before
        breakOn _ [] = ([], [])
        breakOn pat s@(c:cs)
          | pat `isPrefixOf` s = ([], s)
          | otherwise = let (before, after) = breakOn pat cs in (c:before, after)

splitPipe :: String -> [String]
splitPipe raw = filter (not . null) $ map extractId $ splitOn '|' raw
  where extractId p = let p' = trim $ filter (\c -> c /= '(' && c /= ')') p
                          p'' = takeWhile (\c -> c /= ':' && c /= '{') p'
                      in trim p''

splitOn :: Char -> String -> [String]
splitOn _ [] = []
splitOn c s = let (before, rest) = break (== c) s
              in before : case rest of [] -> []; (_:xs) -> splitOn c xs

parseProperties :: String -> Props
parseProperties raw
  | null raw = Map.empty
  | otherwise = Map.fromList $ concatMap parseSeg (splitOn ',' raw)
  where parseSeg seg = case break (== ':') (trim seg) of
          (key, ':':val) -> let k = trim key; v = trim $ filter (\c -> c /= '\'' && c /= '"') val
                            in if null k || null v then [] else [(k, v)]
          _ -> []

-- Simple edge finder: scan for )-[:
findEdges :: String -> [(String, String, String)]
findEdges cleaned = go 0
  where
    len = length cleaned
    go i | i + 4 >= len = []
         | cleaned !! i == ')' && cleaned !! (i+1) == '-' && cleaned !! (i+2) == '[' && cleaned !! (i+3) == ':' =
           case parseEdgeAt i of
             Just (edge, nextI) -> edge : go nextI
             Nothing -> go (i + 1)
         | otherwise = go (i + 1)

    parseEdgeAt marker =
      let srcStart = backtrackParen marker
          srcRaw = take (marker - srcStart) (drop srcStart cleaned)
          bracketStart = marker + 3
      in case elemIndex' ']' bracketStart of
           Nothing -> Nothing
           Just bracketEnd ->
             let relContent = take (bracketEnd - bracketStart) (drop bracketStart cleaned)
                 relContent' = if not (null relContent) && head relContent == ':' then tail relContent else relContent
                 edgeType = trim $ takeWhile (\c -> c /= '{' && c /= ' ') relContent'
                 arrowStart = bracketEnd + 1
             in if arrowStart + 2 < len && cleaned !! arrowStart == '-' && cleaned !! (arrowStart+1) == '>'
                then case elemIndex' '(' (arrowStart + 2) of
                       Nothing -> Nothing
                       Just tgtOpen ->
                         let tgtClose = findCloseParen tgtOpen
                             tgtRaw = take (tgtClose - tgtOpen - 1) (drop (tgtOpen + 1) cleaned)
                         in Just ((srcRaw, edgeType, tgtRaw), tgtClose + 1)
                else Nothing

    backtrackParen marker = go' (marker - 1) 0
      where go' j depth
              | j < 0 = 0
              | cleaned !! j == ')' = go' (j-1) (depth+1)
              | cleaned !! j == '(' = if depth == 0 then j + 1 else go' (j-1) (depth-1)
              | otherwise = go' (j-1) depth

    elemIndex' c start = go'' start
      where go'' i | i >= len = Nothing
                   | cleaned !! i == c = Just i
                   | otherwise = go'' (i+1)

    findCloseParen open = go'' (open + 1) 1
      where go'' i depth
              | i >= len = i
              | cleaned !! i == '(' = go'' (i+1) (depth+1)
              | cleaned !! i == ')' = if depth == 1 then i else go'' (i+1) (depth-1)
              | otherwise = go'' (i+1) depth

parseGG :: String -> GgProgram
parseGG source =
  let cleaned = stripComments' source
      rawEdges = findEdges cleaned
      (nodes0, edgeList) = foldl' processEdge (Map.empty, []) rawEdges
      nodes1 = foldl' processNodeLine nodes0 (filter (not . isInfixOf "-[:") (lines cleaned))
  in GgProgram nodes1 (reverse edgeList)
  where
    processEdge (ns, es) (srcRaw, et, tgtRaw) =
      let sids = splitPipe srcRaw
          tids = splitPipe tgtRaw
          ns' = foldl' ensureNode ns (sids ++ tids)
          e = GgEdge sids tids et Map.empty
      in (ns', e : es)
    ensureNode ns nid = Map.insertWith (\_ old -> old) nid (GgNode nid [] Map.empty) ns
    processNodeLine ns _ = ns -- simplified: edges already created nodes

computeBeta1 :: GgProgram -> Int
computeBeta1 prog = foldl' step 0 (edges prog)
  where step b1 e =
          let s = length (sourceIds e); t = length (targetIds e)
          in case edgeType e of
               "FORK" -> b1 + t - 1
               "FOLD" -> max 0 (b1 - (s - 1))
               "COLLAPSE" -> max 0 (b1 - (s - 1))
               "OBSERVE" -> max 0 (b1 - (s - 1))
               "RACE" -> max 0 (b1 - max 0 (s - t))
               "SLIVER" -> max 0 (b1 - max 0 (s - t))
               "VENT" -> max 0 (b1 - 1)
               _ -> b1

computeVoid :: GgProgram -> Int
computeVoid prog = sum [length (targetIds e) | e <- edges prog, edgeType e == "FORK"]

main :: IO ()
main = do
  args <- getArgs
  let (flags, files) = partition (\a -> "-" `isPrefixOf` a) args
      partition f xs = (filter f xs, filter (not . f) xs)
      beta1Only = "--beta1" `elem` flags
      summary = "--summary" `elem` flags
      benchIters = case dropWhile (/= "--bench") flags of
                     ("--bench":n:_) -> read n :: Int
                     _ -> 0
  case files of
    [] -> hPutStrLn stderr "usage: runghc Becky.hs [--beta1|--summary|--bench N] <file.gg>" >> exitFailure
    (fp:_) -> do
      source <- readFile fp
      if benchIters > 0 then do
        -- Warmup
        let go 0 = return ()
            go n = let !_ = parseGG source in go (n-1)
        go 10
        t1 <- getSystemTime
        go benchIters
        t2 <- getSystemTime
        let ns = fromIntegral (systemSeconds t2 - systemSeconds t1) * 1000000000
                 + fromIntegral (systemNanoseconds t2 - systemNanoseconds t1)
            us = fromIntegral ns / fromIntegral benchIters / 1000.0 :: Double
            p = parseGG source
        printf "%.1fus/iter | %d iterations | %d nodes %d edges | b1=%d | void=%d\n"
          us benchIters (Map.size (nodes p)) (length (edges p)) (computeBeta1 p) (computeVoid p)
      else do
        let p = parseGG source
            b1 = computeBeta1 p
        if beta1Only then print b1
        else if summary then
          printf "%s: %d nodes, %d edges, b1=%d, void=%d\n"
            fp (Map.size (nodes p)) (length (edges p)) b1 (computeVoid p)
        else
          printf "{\"nodes\":%d,\"edges\":%d,\"beta1\":%d}\n"
            (Map.size (nodes p)) (length (edges p)) b1
