import Cocoa
import SwiftyJSON

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    let apiUrl = "https://www.alphavantage.co/"
    let apiFunction = "TIME_SERIES_INTRADAY"
    let apiInterval = "5min"
    let apiOutputSize = "compact"
    let apiDataType = "json"
    let apiKey: String = {
        if let filePath = Bundle.main.path(forResource: "key", ofType: "txt") {
            do {
                return try String(contentsOfFile: filePath).trimmingCharacters(in: .whitespacesAndNewlines)
            } catch {
                fatalError("Unable to parse key.txt")
            }
        } else {
            fatalError("key.txt file not found")
        }
    }()
    
    static var shared: AppDelegate {
        return NSApplication.shared.delegate as! AppDelegate
    }
    
    // MARK: - Properties
    
    var ticker: String {
        get {
            if let ticker = UserDefaults.standard.object(forKey: "ticker") as? String {
                return ticker
            }
            
            UserDefaults.standard.set("AAPL", forKey: "ticker")
            return "AAPL"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "ticker")
        }
    }
    
    var interval: Int {
        get {
            if let interval = UserDefaults.standard.object(forKey: "interval") as? Int {
                return interval
            }
            
            UserDefaults.standard.set(5, forKey: "interval")
            return 5
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "interval")
            newTimer()
        }
    }
    
    var timer: Timer?
    
    private var popover = NSPopover()
    
    private lazy var statusBarItem: NSStatusItem = {
        return NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    }()
    
    // MARK: - Application Lifecycle
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        popover.contentViewController = PreferencesViewController.loadFromStoryboard()
        popover.behavior = .transient
        statusBarItem.button?.title = "Loading..."
        statusBarItem.button?.action = #selector(togglePreferences)
        
        newTimer()
    }
    
    // MARK: - Private Methods
    
    @objc func togglePreferences() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            if let button = statusBarItem.button {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
    
    private func onTimerTick() {
        let url = URL(string:
            "\(apiUrl)query?"
                + "function=\(apiFunction)"
                + "&symbol=\(ticker)"
                + "&interval=\(apiInterval)"
                + "&outputsize=\(apiOutputSize)"
                + "&datatype=\(apiDataType)"
                + "&apikey=\(apiKey)"
            )!
        print(url)
        let task = URLSession.shared.dataTask(with: url) { (data, _, _) in
            guard let data = data else {
                print("Unable to fetch data")
                return
            }
            
            let json = JSON(parseJSON: String(data: data, encoding: .utf8)!)["Time Series (\(self.apiInterval))"].dictionaryValue.sorted { $0.key > $1.key }
            
            let currentData = json.first
            let previousData = json.first { $0.key.split(separator: " ").first != currentData?.key.split(separator: " ").first }
            
            let currentPrice = currentData?.value["4. close"].doubleValue
            let previousPrice = previousData?.value["4. close"].doubleValue
            
            DispatchQueue.main.async {
                self.statusBarItem.button?.title =
                    self.ticker + ": " +
                    self.toCurrency(currentPrice) + " | " +
                    self.toPercentage(current: currentPrice, previous: previousPrice)
            }
        }
        task.resume()
    }
    
    private func newTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: Double(interval) * 60.0, repeats: true) { _ in self.onTimerTick() }
        timer!.fire()
    }
    
    private func toCurrency(_ price: Double?) -> String {
        guard let price = price else {
            return "null"
        }
        
        let formatter = NumberFormatter()
        formatter.usesGroupingSeparator = true
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: price))!
    }
    
    private func toPercentage(current: Double?, previous: Double?) -> String {
        guard let current = current, let previous = previous else {
            return "null"
        }
        
        let raw = (current - previous) / previous
        return "\((raw * 10000).rounded() / 100.0)%"
    }
    
}

