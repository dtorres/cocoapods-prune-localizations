require_relative 'pruner'
module CocoapodsPruneLocalizations
  Pod::HooksManager.register('cocoapods-prune-localizations', :post_install) do |context, user_options|
    Pruner.new(context, user_options).prune!
  end
end