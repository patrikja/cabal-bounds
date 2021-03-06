{-# LANGUAGE DeriveDataTypeable, CPP #-}
{-# OPTIONS_GHC -w #-}

module CabalBounds.Args
   ( Args(..)
   , get
   , outputFile
   , defaultDrop
   , defaultUpdate
   , defaultDump
   ) where

import System.Console.CmdArgs hiding (ignore)
import CabalBounds.VersionComp (VersionComp(..))

#ifdef CABAL
import Data.Version (showVersion)
import Paths_cabal_bounds (version)
#endif

data Args = Drop { upper      :: Bool
                 , library    :: Bool
                 , executable :: [String]
                 , testSuite  :: [String]
                 , benchmark  :: [String]
                 , only       :: [String]
                 , ignore     :: [String]
                 , output     :: FilePath
                 , cabalFile  :: FilePath
                 }
          | Update { lower           :: Bool
                   , upper           :: Bool
                   , lowerComp       :: Maybe VersionComp
                   , upperComp       :: Maybe VersionComp
                   , library         :: Bool
                   , executable      :: [String]
                   , testSuite       :: [String]
                   , benchmark       :: [String]
                   , only            :: [String]
                   , ignore          :: [String]
                   , missing         :: Bool
                   , output          :: FilePath
                   , fromFile        :: FilePath
                   , haskellPlatform :: String
                   , cabalFile       :: FilePath
                   , setupConfigFile :: [FilePath]
                   }
          | Dump { output     :: String
                 , cabalFiles :: [FilePath]
                 }
          deriving (Data, Typeable, Show, Eq)


get :: IO Args
get = cmdArgsRun . cmdArgsMode $ modes [dropArgs, updateArgs, dumpArgs]
   &= program "cabal-bounds"
   &= summary summaryInfo
   &= help "A command line program for managing the bounds/versions of the dependencies in a cabal file."
   &= helpArg [explicit, name "help", name "h"]
   &= versionArg [explicit, name "version", name "v", summary versionInfo]
   where
      summaryInfo = ""


outputFile :: Args -> FilePath
outputFile args
   | not isDumpArgs && null (output args) = cabalFile args
   | otherwise                            = output args
   where
      isDumpArgs = case args of Dump {} -> True; _ -> False


defaultDrop :: Args
defaultDrop = Drop
   { upper           = def
   , library         = def
   , executable      = def
   , testSuite       = def
   , benchmark       = def
   , only            = def
   , ignore          = def
   , output          = def
   , cabalFile       = def
   }


defaultUpdate :: Args
defaultUpdate = Update
   { lower           = def
   , upper           = def
   , lowerComp       = def
   , upperComp       = def
   , library         = def
   , executable      = def
   , testSuite       = def
   , benchmark       = def
   , only            = def
   , ignore          = def
   , missing         = def
   , output          = def
   , fromFile        = def
   , haskellPlatform = def
   , cabalFile       = def
   , setupConfigFile = def
   }


defaultDump :: Args
defaultDump = Dump
   { output     = def
   , cabalFiles = def
   }


dropArgs :: Args
dropArgs = Drop
   { upper      = def &= explicit &= name "upper" &= name "U"
                      &= help "Only the upper bound is dropped, otherwise both - the lower and upper - bounds are dropped."
   , library    = def &= explicit &= name "library" &= name "l" &= help "Only the bounds of the library are modified."
   , executable = def &= typ "NAME" &= help "Only the bounds of the executable are modified."
   , testSuite  = def &= typ "NAME" &= help "Only the bounds of the test suite are modified."
   , benchmark  = def &= typ "NAME" &= help "Only the bounds of the benchmark are modified."
   , only       = def &= explicit &= typ "DEPENDENCY" &= name "only" &= name "O"
                      &= help "Only the bounds of the dependency are modified."
   , ignore     = def &= explicit &= typ "DEPENDENCY" &= name "ignore" &= name "I"
                      &= help "This dependency is ignored, not modified in any way."
   , output     = def &= explicit &= typ "FILE" &= name "output" &= name "o"
                      &= help "Save modified cabal file to file, if empty, the cabal file is modified inplace."
   , cabalFile  = def &= argPos 0 &= typ "CABAL-FILE"
   }


updateArgs :: Args
updateArgs = Update
   { lower           = def &= explicit &= name "lower" &= name "L"
                           &= help "Only the lower bound is updated. The same as using '--lowercomp=minor'."
   , upper           = def &= explicit &= name "upper" &= name "U"
                           &= help "Only the upper bound is updated. The same as using '--uppercomp=major2'."
   , lowerComp       = def &= explicit &= name "lowercomp"
                           &= help "Only the lower bound is updated with the specified version component. (major1, major2 or minor)"
   , upperComp       = def &= explicit &= name "uppercomp"
                           &= help "Only the upper bound is updated with the specified version component. (major1, major2 or minor)"
   , missing         = def &= help "Only the dependencies having missing bounds are updated."
   , fromFile        = def &= typ "FILE" &= help "Update bounds by the library versions spedified in the given file."
   , haskellPlatform = def &= explicit &= typ "VERSION" &= name "haskell-platform"
                           &= help "Update bounds by the library versions of the specified haskell platform version"
   , setupConfigFile = def &= args &= typ "SETUP-CONFIG-FILE"
   }


dumpArgs :: Args
dumpArgs = Dump
   { output     = def &= explicit &= typ "FILE" &= name "output" &= name "o"
                      &= help "Save libraries with lower bounds to file, if empty, then it's written to stdout."
   , cabalFiles = def &= args &= typ "CABAL_FILE"
   }


versionInfo :: String
versionInfo =
#ifdef CABAL
   "cabal-bounds version " ++ showVersion version
#else
   "cabal-bounds version unknown (not built with cabal)"
#endif


