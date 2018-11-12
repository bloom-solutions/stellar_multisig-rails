$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "stellar_multisig/rails/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "stellar_multisig-rails"
  s.version     = StellarMultisig::Rails::VERSION
  s.authors     = ["Ramon Tayag"]
  s.email       = ["ramon.tayag@gmail.com"]
  s.homepage    = "https://github.com/bloom-solutions/stellar_multisig-rails"
  s.summary     = "Use Stellar Multisignatures to easily secure wallets"
  s.description = "Description of StellarMultisig::Rails."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.2.1"
  s.add_dependency "rotp"
  s.add_dependency "addressable", "~> 2.5.2"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "factory_bot_rails"
end
