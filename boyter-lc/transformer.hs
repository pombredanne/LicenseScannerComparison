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
 -}
{-# OPTIONS_GHC -threaded      #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RankNTypes        #-}
{-# LANGUAGE DeriveGeneric     #-}
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

data Lic
  = Lic
  { licenseId :: Text
  } deriving Show
data RawFinding
  = RawFinding
  { rfFilename :: Text
  , rfDirectory :: Text
  , rfLicenseGuesses :: Maybe [Lic]
  , rfLicenseRoots :: Maybe [Lic]
  } deriving Show
data Finding
  = Finding
  { path :: Text
  , licenses :: [Text]
  } deriving Show

unRaw :: RawFinding -> Finding
unRaw rf = let
  p = rfDirectory rf `Tx.append` rfFilename rf
  lics = L.nub . P.map licenseId $ (fromMaybe [] $ rfLicenseGuesses rf) ++ (fromMaybe [] $ rfLicenseRoots rf)
  in Finding p lics

instance FromJSON Lic where
  parseJSON = withObject "Lic" $
    \v -> Lic <$> v .: "LicenseId"

instance FromJSON RawFinding where
  parseJSON = withObject "RawFinding" $
    \v -> RawFinding
            <$> v .: "Filename"
            <*> v .: "Directory"
            <*> v .:? "LicenseGuesses"
            <*> v .:? "LicenseRoots"

parseJsonSource :: FilePath -> IO (Either String [Finding])
parseJsonSource source = do
  content <- TB.strict $ TB.input source
  return $ (mapRight (P.map unRaw) . A.eitherDecodeStrict') content

convertToCSV :: [Finding] -> BS.ByteString
convertToCSV = let
    options = CSV.defaultEncodeOptions
      { CSV.encDelimiter = W8._semicolon
      , CSV.encUseCrLf = False
      , CSV.encQuoting = CSV.QuoteMinimal }
    toTuples :: Finding -> (Text, Text, Text)
    toTuples f = (path f, Tx.intercalate "," (licenses f), "")
  in BSL.toStrict . (CSV.encodeWith options) . L.map toTuples

getSourceFileFromDir :: FilePath -> FilePath
getSourceFileFromDir = (</> "output.json")

main :: IO ()
main = let
    optionsParser :: T.Parser (FilePath, FilePath)
    optionsParser = (,) <$> argPath "sourceDir" "SourceDir"
                 <*> argPath "target" "Target"
  in do
    (sourceDir, target) <- options "Transformer" optionsParser
    parsed <- (parseJsonSource . getSourceFileFromDir) sourceDir
    case parsed of
      Left error -> print error
      Right v    -> (writeTextFile target . Tx.decodeUtf8 . convertToCSV) v
