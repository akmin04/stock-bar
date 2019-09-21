import Cocoa

class PreferencesViewController: NSViewController {
    
    // MARK: - Interface Builder
    
    @IBOutlet weak var tickerTextField: NSTextField!
    @IBOutlet weak var intervalPopUpButton: NSPopUpButton!
    @IBOutlet weak var doneButton: NSButton!
    @IBOutlet weak var quitButton: NSButton!
    
    static func loadFromStoryboard() -> PreferencesViewController{
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let identifier = NSStoryboard.SceneIdentifier("PreferencesViewController")
        
        guard let viewcontroller = storyboard.instantiateController(withIdentifier: identifier) as? PreferencesViewController else {
          fatalError("Can't find preferences view controller")
        }
        return viewcontroller
    }
    
    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        doneButton.keyEquivalent = "\r"
        doneButton.action = #selector(donePressed)
        quitButton.action = #selector(quitPressed)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        tickerTextField.stringValue = AppDelegate.shared.ticker
        intervalPopUpButton.selectItem(at: [1, 5, 15, 30, 60].firstIndex(of: AppDelegate.shared.interval)!)
    }
    
    // MARK: - Private Methods
    
    @objc private func donePressed() {
        AppDelegate.shared.togglePreferences()
        AppDelegate.shared.ticker = tickerTextField.stringValue.uppercased().filter { $0 != " " }
        AppDelegate.shared.interval = Int(intervalPopUpButton.selectedItem!.title.filter { "0123456789".contains($0) })!
    }
    
    @objc private func quitPressed() {
        NSApp.terminate(nil)
    }
    
}
