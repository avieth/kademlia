{-|
Module      : Protocol
Description : Test for Network.Kademlia.Protocol

Tests specific to Network.Kademlia.Protocol.
-}

module Protocol
       ( parseCheck
       , lengthCheck
       ) where

import qualified Data.ByteString           as B
import           Test.QuickCheck           (Property, conjoin, counterexample, (===),
                                            (==>))

import           Network.Kademlia.Protocol (parse, serialize)
import           Network.Kademlia.Types    (Command (..), Node (..), Signal (..))

import           TestTypes                 (IdType (..))

-- | A signal is the same as its serialized form parsed
parseCheck :: Signal IdType String -> Property
parseCheck s = test . (>>= parse (peer . source $ s))
             . fmap head . serialize 99999 nid . command $ s
    where nid = nodeId . source $ s
          test (Left   _) = counterexample "Parsing failed" False
          test (Right s') = counterexample
            ("Signals differ:\nIn:  " ++ show s ++ "\nOut: "
                 ++ show s' ++ "\n") $ s === s'

-- | Commands are cut into small enough pieces.
lengthCheck :: Signal IdType String -> Property
lengthCheck s =
    isReturnNodes (command s) ==>
    case serialize partLen (nodeId . source $ s) $ command s of
        Left er   -> counterexample ("Serialization error: " ++ er) False
        Right bss -> conjoin $ flip map bss $
            \bs -> counterexample (err bs) $ B.length bs <= partLen
  where
    err bs = "Serialized part of signal is too long: " ++ show (B.length bs) ++ " bytes"
    partLen = 100
    isReturnNodes (RETURN_NODES _ _ _) = True
    isReturnNodes _                    = False
