module Test.GitHUD.Config.Parse (
  configParserTests
  ) where

import Test.Tasty
import Test.Tasty.HUnit

import Text.Parsec (parse)
import Text.Parsec.String (Parser)

import GitHUD.Config.Parse
import GitHUD.Config.Types
import GitHUD.Terminal.Types

configParserTests :: TestTree
configParserTests = testGroup "Config Parser Test"
  [ testItemParser
    , testCommentParser
    , testConfigItemFolder
    , testColorConfigToColor
    , testIntensityConfigToIntensity
  ]

testItemParser :: TestTree
testItemParser = testGroup "#itemParser"
  [ testCase "properly formed config item" $
      utilConfigItemParser itemParser "some_test_key=some Complex ⚡ value"
      @?= Item "some_test_key" "some Complex ⚡ value"

    , testCase "dash characters are not allowed in keys" $
        utilConfigItemParser itemParser "some-key=dash"
        @?= ErrorLine

    , testCase "num characters are not allowed in keys" $
        utilConfigItemParser itemParser "some123=dash"
        @?= ErrorLine

    , testCase "empty keys are not allowed" $
        utilConfigItemParser itemParser "=dash"
        @?= ErrorLine

    , testCase "Comment should not work" $
        utilConfigItemParser itemParser "#some comment"
        @?= ErrorLine
  ]

testCommentParser :: TestTree
testCommentParser = testGroup "#commentParser"
  [ testCase "proper comment" $
      utilConfigItemParser commentParser "#some comment\n"
      @?= Comment

    , testCase "not a comment if start with a space" $
        utilConfigItemParser commentParser " #some non comment\n"
        @?= ErrorLine
  ]

testConfigItemFolder :: TestTree
testConfigItemFolder = testGroup "#configItemFolder"
  [   testCase "Comment should have no impact on the config" $
        configItemsFolder defaultConfig (Comment)
        @?= defaultConfig

    , testCase "ErrorLines should have no impact on the config" $
        configItemsFolder defaultConfig (ErrorLine)
        @?= defaultConfig

    , testCase "Key: git_repo_indicator" $
        configItemsFolder defaultConfig (Item "git_repo_indicator" "foo")
        @?= defaultConfig { confRepoIndicator = "foo" }

    , testCase "Key: no_upstream_text" $
        configItemsFolder defaultConfig (Item "no_upstream_text" "foo")
        @?= defaultConfig { confNoUpstreamString = "foo" }

    , testCase "Key: no_upstream_indicator" $
        configItemsFolder defaultConfig (Item "no_upstream_indicator" "foo")
        @?= defaultConfig { confNoUpstreamIndicator = "foo" }

    , testCase "Key: no_upstream_indicator_color" $
        configItemsFolder defaultConfig (Item "no_upstream_indicator_color" "Black")
        @?= defaultConfig { confNoUpstreamIndicatorColor = Black }

    , testCase "Key: no_upstream_indicator_color - invalid color" $
        configItemsFolder defaultConfig (Item "no_upstream_indicator_color" "FOO")
        @?= defaultConfig { confNoUpstreamIndicatorColor = White }

    , testCase "Key: no_upstream_indicator_intensity" $
        configItemsFolder defaultConfig (Item "no_upstream_indicator_intensity" "Dull")
        @?= defaultConfig { confNoUpstreamIndicatorIntensity = Dull }

    , testCase "Key: no_upstream_indicator_intensity - invalid intensity" $
        configItemsFolder defaultConfig (Item "no_upstream_indicator_intensity" "FOO")
        @?= defaultConfig { confNoUpstreamIndicatorIntensity = Dull }

    , testCase "Key: remote_commits_indicator" $
        -- (((expectKey "remote_commits_indicator")
        --   (withValue "FOO"))
        --   `toChangeField` confRemoteCommitsIndicator)
        --   `toValue` "FOO"
        expectValue "FOO" $
          toBeInField confRemoteCommitsIndicator $
            forConfigItemKey "remote_commits_indicator" $
              withValue "FOO"
  ]

expectValue :: (Eq a, Show a) => a -> a -> Assertion
expectValue expected actual = actual @?= expected

toBeInField :: (Config -> a) -> Config -> a
toBeInField accessor config = accessor config

forConfigItemKey :: String -> String -> Config
forConfigItemKey key value =
  configItemsFolder defaultConfig (Item key value)

-- expectKey :: String -> (String -> Config)
-- expectKey key = (configItemsFolder defaultConfig) . (Item key)

withValue :: a -> a
withValue = id

-- toChangeField :: Config -> (Config -> String) -> String
-- toChangeField config field = field config
--
-- toValue :: String -> String -> Assertion
-- toValue actual expected = actual @?= expected
--
-- infix 1 `toChangeField`

utilConfigItemParser :: Parser ConfigItem -> String -> ConfigItem
utilConfigItemParser parser str =
  either
    (const ErrorLine)
    id
    (parse parser "" str)

testIntensityConfigToIntensity :: TestTree
testIntensityConfigToIntensity = testGroup "#intensityConfigToIntensity"
  [   testCase "valid intensity - return it" $
        intensityConfigToIntensity "Vivid" @?= Vivid

    , testCase "invalid intensity - default to Dull" $
        intensityConfigToIntensity "Foo" @?= Dull
  ]

testColorConfigToColor :: TestTree
testColorConfigToColor = testGroup "#colorConfigToColor"
  [   testCase "valid color - return it" $
        colorConfigToColor "Cyan" @?= Cyan

    , testCase "invalid color - default to White" $
        colorConfigToColor "Foo" @?= White
  ]
