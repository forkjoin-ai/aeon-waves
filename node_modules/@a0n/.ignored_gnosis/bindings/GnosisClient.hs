module GnosisClient (
  GnosisClient(..),
  GnosisResult(..),
  defaultClient,
  run,
  lint,
  analyze,
  verify,
  runTopology,
  testTopology
) where

import System.Exit (ExitCode(..))
import System.Process (readProcessWithExitCode)

data GnosisClient = GnosisClient {
  binary :: String
} deriving (Show, Eq)

data GnosisResult = GnosisResult {
  exitCode :: Int,
  stdout :: String,
  stderr :: String
} deriving (Show, Eq)

defaultClient :: GnosisClient
defaultClient = GnosisClient { binary = "gnosis" }

run :: GnosisClient -> [String] -> IO GnosisResult
run client args = do
  (code, out, err) <- readProcessWithExitCode (binary client) args ""
  let normalizedCode = case code of
        ExitSuccess -> 0
        ExitFailure value -> value
  pure GnosisResult {
    exitCode = normalizedCode,
    stdout = out,
    stderr = err
  }

lint :: GnosisClient -> String -> Maybe String -> Bool -> IO GnosisResult
lint client topologyPath target asJson =
  run client (baseArgs ++ targetArgs ++ jsonArgs)
  where
    baseArgs = ["lint", topologyPath]
    targetArgs = case target of
      Nothing -> []
      Just value -> ["--target", value]
    jsonArgs = if asJson then ["--json"] else []

analyze :: GnosisClient -> String -> Bool -> IO GnosisResult
analyze client targetPath asJson =
  run client (["analyze", targetPath] ++ if asJson then ["--json"] else [])

verify :: GnosisClient -> String -> Maybe String -> IO GnosisResult
verify client topologyPath tlaOut =
  run client (["verify", topologyPath] ++ tlaOutArgs)
  where
    tlaOutArgs = case tlaOut of
      Nothing -> []
      Just value -> ["--tla-out", value]

runTopology :: GnosisClient -> String -> Bool -> IO GnosisResult
runTopology client topologyPath nativeRuntime =
  run client (["run", topologyPath] ++ if nativeRuntime then ["--native"] else [])

testTopology :: GnosisClient -> String -> IO GnosisResult
testTopology client testPath = run client ["test", testPath]
