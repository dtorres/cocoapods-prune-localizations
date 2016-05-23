require_relative '../lib/pruner'

describe CocoapodsPruneLocalizations do
    describe 'Pruner' do
        it "normalizes localizations" do
            normal_opts = CocoapodsPruneLocalizations::Pruner.user_options(nil, "localizations" => ["es", "en.lproj", "de", "it.lproj"])
            expect(normal_opts["localizations"]).to eq ["es.lproj", "en.lproj", "de.lproj", "it.lproj"]
        end
    end
end
    