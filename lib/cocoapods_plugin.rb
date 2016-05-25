require_relative 'pruner'
module CocoapodsPruneLocalizations
  Pod::HooksManager.register('cocoapods-prune-localizations', :pre_install) do |context, user_options|
    Pruner.new(context, user_options)
  end
end