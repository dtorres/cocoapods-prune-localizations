require 'cocoapods'
require 'claide/command/plugin_manager'

CLAide::Command::PluginManager.load_plugins('cocoapods')
Pod::Config.instance.silent = true

def generate_podfile(localizations = [], used_pods = [])
    Pod::Podfile.new do
        opts = {}
        opts[:localizations] = localizations unless localizations.empty?
        platform :ios, '9.0'
        plugin 'cocoapods-prune-localizations', opts
        
        target 'iOSTarget' do
            used_pods.each do |pod_dict|
                name = pod_dict[:name]
                opts = {}
                opts[:path] ||= pod_dict[:path]
                
                pod name, opts
            end
        end
    end
end

def lproj_in_bundle(bundle_path)
    lprojs = []
    Dir.foreach(bundle_path) do |filename|
        if filename.end_with? ".lproj"
            lprojs << File.basename(filename)
        elsif filename.end_with? ".bundle"
            lprojs += lproj_in_bundle(File.join(bundle_path, filename))
        end
    end
    lprojs
end

def resource_files(group)
    resGroups = group.recursive_children_groups.select do |group|
        group.name == "Resources"
    end
    
    resGroups.each do |resGroup|
        resGroup.files.each do |file|
            yield file
        end
    end
end

describe 'Podfile integration' do
    
    before(:all) do
        @original_dir = Dir.pwd
        @test_dir = Dir.mktmpdir("prune-loc")
    end
    
    before(:each) do
        @sandbox = Pod::Sandbox.new File.join(@test_dir, "/Pods");
        FileUtils.cp_r File.join(@original_dir, 'spec/fixtures/Dummy Targets'), @test_dir
    end
    
    after(:each) do
        FileUtils.rm_r @sandbox.root
    end
    
    it 'calls original post_install hook' do
        Dir.chdir(@test_dir) do
            podfile = generate_podfile
            
            called = false
            podfile.post_install do |installer|
                called = true
            end
            
            installer = Pod::Installer.new(@sandbox, podfile, nil)
            installer.installation_options.integrate_targets = false
            
            installer.install!
            
            expect(called).to be_truthy
        end
    end
    
    it 'keeps only specified languages in Resources' do
        
        pods_to_use = [{:name => "FormatterKit"}]
        
        Dir.chdir(@test_dir) do
            langs = ["es.lproj", "en.lproj"]
            podfile = generate_podfile(langs, pods_to_use)
            
            installer = Pod::Installer.new(@sandbox, podfile, nil)
            installer.installation_options.integrate_targets = false
            
            installer.install!
            
            project = installer.pods_project
            group = project.pod_group(pods_to_use[0][:name])
            
            found_langs = Set.new
            
            resource_files(group) do |file|
                found_langs.add File.basename(file.path) if file.path.end_with? ".lproj"
            end
            
            expect(found_langs).to eq langs.to_set
        end
    end
    
    def verify_group(group, langs)
        found_bundles = []
    
        resource_files(group) do |file|
            found_bundles << file.real_path if file.path.end_with? ".bundle"
        end
    
        found_langs = found_bundles.map {|path| lproj_in_bundle(path)}.flatten!.to_set
        expect(found_langs).to eq langs.to_set
    end

    it 'keeps only specified languages in Bundles' do
        
        pods_to_use = [{:name => "DateTools"}]
        
        Dir.chdir(@test_dir) do
            langs = ["es.lproj", "en.lproj"]
            podfile = generate_podfile(langs, pods_to_use)
            
            installer = Pod::Installer.new(@sandbox, podfile, nil)
            installer.installation_options.integrate_targets = false
            
            installer.install!
            
            project = installer.pods_project
            
            verify_group(project.pod_group(pods_to_use[0][:name]), langs)
        end
    end

    it 'keeps only specified languages in nested bundles' do
        pods_to_use = [{:name => "googleplus-ios-sdk"}]
        
        Dir.chdir(@test_dir) do
            langs = ["it.lproj", "ja.lproj"]
            podfile = generate_podfile(langs, pods_to_use)
            
            installer = Pod::Installer.new(@sandbox, podfile, nil)
            installer.installation_options.integrate_targets = false
            
            installer.install!
            
            project = installer.pods_project
            
            verify_group(project.pod_group(pods_to_use[0][:name]), langs)
        end
    end
    
end
