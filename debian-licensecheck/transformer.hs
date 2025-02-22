#!/usr/bin/env stack
{- stack script --resolver=lts-11.9
 --package=turtle
 --package=text
 --package=aeson
 --package=vector
 --package=either
 --package=cassava
 --package=word8
 --package=bytestring
 --package=foldl
 --package=MissingH
 --package=containers
 -}
{-# OPTIONS_GHC -threaded        #-}
{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE RankNTypes          #-}
{-# LANGUAGE DeriveGeneric       #-}
{-# LANGUAGE ScopedTypeVariables #-}
import Prelude hiding (FilePath)
import qualified Prelude as P
import Turtle as T
import Turtle.Bytes as TB
import GHC.Generics
import Data.Aeson as A
import Data.Aeson.Types as A
import qualified Data.Vector as V
import Data.Text as Tx
import Data.Text.IO as Tx
import Data.Text.Encoding as Tx
import Data.Maybe
import Data.Either.Combinators
import Data.List as L
import qualified Data.Csv as CSV
import Data.Word8 as W8
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as BSL
import qualified Control.Foldl as F
import qualified Data.String.Utils as MH
import qualified Data.Map as Map

data Finding
  = Finding
  { path :: Text
  , licenses :: [Text]
  , origLicenses :: [Text]
  } deriving (Show, Eq)

instance Ord Finding where
  f <= f' = (path f) <= (path f')

parseLine :: Line -> Finding
parseLine l = let
    splitted = splitOn "\t" (T.lineToText l)
    file = L.head splitted
    lics = (L.map (Tx.strip . Tx.pack . (MH.replace "GENERATED FILE" "") . Tx.unpack) $ L.tail splitted)
  in Finding file lics lics

convertToCSV :: [Finding] -> BS.ByteString
convertToCSV = let
    options = CSV.defaultEncodeOptions
      { CSV.encUseCrLf = False
      , CSV.encQuoting = CSV.QuoteMinimal }
    toTuples :: Finding -> (Text, Text, Text)
    toTuples f = (path f, Tx.intercalate ";" ((L.sort . licenses) f), Tx.intercalate ";" ((L.sort . origLicenses) f))
  in BSL.toStrict . (CSV.encodeWith options) . L.map toTuples

getSourceFileFromDir :: FilePath -> FilePath
getSourceFileFromDir = (</> "output")

rewriteMap :: Map.Map Text [Text]
rewriteMap = Map.fromList
  [ ("GENERATED FILE",[])
  , ("BSL (v1.0)", ["BSL-1.0"])
  , ("zlib/libpng", ["Zlib"])
  , ("Apache (v2.0)", ["Apache-2.0"])
  , ("MPL (v1.0)", ["MPL-1.0"]), ("MPL (v1.1)", ["MPL-1.1"]), ("MPL (v2.0)", ["MPL-2.0"])
  , ("GPL (v2)", ["GPL-2.0-only"]), ("GPL (v2 or later)", ["GPL-2.0-or-later"])
  , ("GPL (v2.1)", ["GPL-2.1-only"]), ("GPL (v2.1 or later)", ["GPL-2.1-or-later"])
  , ("GPL (v3)", ["GPL-3.0-only"]), ("GPL (v3 or later)", ["GPL-3.0-or-later"])
  , ("LGPL (v2)", ["LGPL-2.0-only"]), ("LGPL (v2 or later)", ["LGPL-2.0-or-later"])
  , ("LGPL (v2.1)", ["LGPL-2.1-only"]), ("LGPL (v2.1 or later)", ["LGPL-2.1-or-later"])
  , ("AGPL (v1)", ["AGPL-1.0-only"]), ("AGPL (v1 or later)", ["AGPL-1.0-or-later"])
  , ("AGPL (v3)", ["AGPL-3.0-only"]), ("AGPL (v3 or later)", ["AGPL-3.0-or-later"])
  , ("BSL (v1)", ["BSL-1.0"])
  , ("BSD (2 clause)", ["BSD-2-Clause"])
  , ("BSD (3 clause)", ["BSD-3-Clause"])
  , ("libpng", ["Libpng"])
  ]

rewriteFindings :: Map.Map Text [Text] -> [Finding] -> [Finding]
rewriteFindings map = let
    rewriteLicense lic = case lic `Map.lookup` map of
      Just newLics -> newLics
      otherwise    -> [lic]
    rewriteFinding finding@Finding{ licenses = lics } = finding { licenses = L.concatMap rewriteLicense lics }
  in L.map rewriteFinding

main :: IO ()
main = let
    optionsParser :: T.Parser (FilePath, FilePath)
    optionsParser = (,) <$> argPath "sourceDir" "SourceDir"
                 <*> argPath "target" "Target"
  in do
    (sourceDir, target) <- options "Transformer" optionsParser
    input <- fold (T.input (getSourceFileFromDir sourceDir)) (F.list)
    let groupedFindings = L.groupBy (\ f1 -> \ f2 -> (path f1 == path f2)) $ L.map parseLine input
    let collectedFindings = L.map (\ fs -> let
                                        p = path $ L.head fs
                                        ls = L.concatMap licenses fs
                                        origLs = L.concatMap origLicenses fs
                                      in Finding p ls origLs) groupedFindings
    (writeTextFile target . Tx.decodeUtf8 . convertToCSV . L.sort . rewriteFindings rewriteMap) collectedFindings
