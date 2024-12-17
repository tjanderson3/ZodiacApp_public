import SwiftUI
import Foundation
import CoreLocation

struct ContentView: View {
    @AppStorage("isFirstTimeUser") var isFirstTimeUser: Bool = true

    var body: some View {
        if isFirstTimeUser {
            UserDetailsView()
        } else {
            MainContentView()
        }
    }
}


struct ConversationView: View {
    var initialMessage: String
    @State private var userInput = ""
    @State private var messages: [String]
    @State private var threadId: String? = nil  // Managing threadId state
    let apiURL = URL(string: "removed url for security purposes")!

    init(initialMessage: String) {
        self.initialMessage = initialMessage
        _messages = State(initialValue: [initialMessage])
    }

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(messages, id: \.self) { message in
                        Text(message)
                            .padding()
                            .background(message.starts(with: "You: ") ? Color.blue : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .frame(maxWidth: .infinity, alignment: message.starts(with: "You: ") ? .trailing : .leading)
                    }
                }
            }
            .padding()

            HStack {
                TextField("Type your question here...", text: $userInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button("Send") {
                    sendMessage()
                }
                .padding()
            }
        }
        .onDisappear {
            if let threadId = threadId {
                closeSession(threadId: threadId)
            }
        }
    }

    func sendMessage() {
        let trimmedInput = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedInput.isEmpty {
            messages.append("You: \(trimmedInput)")
            performAPIRequest(userInput: trimmedInput, action: "message")
            userInput = ""
        }
    }

    func performAPIRequest(userInput: String, action: String) {
        var requestBody: [String: Any] = ["user_input": userInput, "action": action]
        if let threadId = threadId {
            requestBody["thread_id"] = threadId
        }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            print("Error: Unable to encode parameters as JSON")
            return
        }
        
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let responseMessage = jsonResponse["response"] as? String {
                       
                        DispatchQueue.main.async {
                            self.messages.append("AI: \(responseMessage)")
                            self.threadId = jsonResponse["thread_id"] as? String
                        }
                    }
                } catch {
                    print("Error parsing JSON: \(error.localizedDescription)")
                }
            } else if let error = error {
                print("HTTP Error: \(error.localizedDescription)")
            }
        }.resume()
    }

    func closeSession(threadId: String) {
        performAPIRequest(userInput: "", action: "close")
    }
}




struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ContentView()
        }
    }
}

struct UserDetailsView: View {
    @State private var name: String = ""
    @State private var birthday: Date = Date()
    @State private var birthTime: Date = Date()
    @State private var city: String = ""
    @State private var state: String = ""
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Your Details")) {
                    TextField("Name", text: $name)
                    DatePicker("Birthday", selection: $birthday, displayedComponents: [.date])
                    DatePicker("Birth Time", selection: $birthTime, displayedComponents: [.hourAndMinute])
                    TextField("City", text: $city)
                    TextField("State", text: $state)
                }
                
                Button("Submit") {
                    UserDefaults.standard.set(name, forKey: "userName")
                    UserDefaults.standard.set(birthday, forKey: "userBirthday")
                    UserDefaults.standard.set(city, forKey: "userCity")
                    UserDefaults.standard.set(state, forKey: "userState")
                    UserDefaults.standard.set(false, forKey: "isFirstTimeUser")
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .navigationBarTitle("Welcome", displayMode: .inline)
        }
    }
}

struct MainContentView: View {
    let gridItems = [GridItem(.flexible()), GridItem(.flexible())]
    let emojis = ["🛒", "📱", "💻", "🌍", "🎮", "🎨"]
    let initialMessages = [
        "What kind of food do you want to eat?",
        "What tech gadget are you looking for?",
        "Need help with software issues?",
        "Discover places around the world!",
        "Find the best games here!",
        "Explore your creative side!"
    ]

    var body: some View {
        NavigationView {
            VStack {
                Text("New App")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()

                LazyVGrid(columns: gridItems, spacing: 20) {
                    ForEach(emojis.indices, id: \.self) { index in
                        if index == 5 {  // Assuming "Page 6" is at index 5 (6th page)
                            NavigationLink(destination: ChartView()) {
                                PageView(emoji: emojis[index], label: "Astrological Chart")
                            }
                        }
                        else if index == 4 {
                            NavigationLink(destination: CompatibilityOptionView()){
                                PageView(emoji: emojis[index], label: "Compatibility")
                            }
                        }
                        else {
                            NavigationLink(destination: ConversationView(initialMessage: initialMessages[index])) {
                                PageView(emoji: emojis[index], label: "Page \(index + 1)")
                            }
                        }
                    }
                }
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray)
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .background(Color.gray.edgesIgnoringSafeArea(.all))
    }
}

struct PageView: View {
    var emoji: String
    var label: String

    var body: some View {
        VStack {
            Text(emoji)
                .font(.system(size: 50))
            Text(label)
                .foregroundColor(.white)
                .font(.title2)
        }
        .frame(width: 150, height: 150)
        .background(Color.black)
        .cornerRadius(10)
    }
}


struct ChartView: View {
    @State private var planets: [PlanetInfo] = []

    var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(planets, id: \.id) { planet in
                        NavigationLink(destination: PlanetDetailView(planet: planet)) {
                            VStack(alignment: .leading) {
                                Text("\(planet.emoji) \(planet.name)")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .padding(.bottom, 2)
                                Text("Sign: \(fullSignName(from: planet.sign)) (\(planet.quality), \(planet.element))")
                                    .font(.body)
                                    .padding(.bottom, 2)
                                Text("House: \(fullHouseName(from: planet.house)), Retrograde: \(planet.retrograde ? "Yes" : "No")")
                                    .font(.body)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .shadow(color: .gray, radius: 3, x: 0, y: 3)
                        }
                    }
                }
                .padding()
            }
            .onAppear {
                generateChart()
            }
            .navigationTitle("Your Astrological Chart")
        }

    private func generateChart() {
        if let savedData = UserDefaults.standard.data(forKey: "userPlanetInfo") {
            if let savedPlanets = try? JSONDecoder().decode([PlanetInfo].self, from: savedData) {
                planets = savedPlanets
                return
            }
        }

        let name = UserDefaults.standard.string(forKey: "userName") ?? "N/A"
        let city = UserDefaults.standard.string(forKey: "userCity") ?? "N/A"
        let state = UserDefaults.standard.string(forKey: "userState") ?? "N/A"
        let birthday = UserDefaults.standard.object(forKey: "userBirthday") as? Date ?? Date()

        fetchAndSaveChart(name: name, city: city, state: state, birthday: birthday)
    }

    private func fetchAndSaveChart(name: String, city: String, state: String, birthday: Date) {
        let geocoder = CLGeocoder()
        let fullAddress = "\(city), \(state)"

        geocoder.geocodeAddressString(fullAddress) { (placemarks, error) in
            guard let placemark = placemarks?.first, let location = placemark.location else {
                print("Geocoding failed: \(error?.localizedDescription ?? "No error description")")
                return
            }

            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: birthday)
            let timezone = TimeZone.current.identifier

            let headers = [
                "content-type": "application/json",
                "X-RapidAPI-Key": "removed key for security purposes",
                "X-RapidAPI-Host": "astrologer.p.rapidapi.com"
            ]

            let parameters = ["subject": [
                "name": name,
                "year": components.year!,
                "month": components.month!,
                "day": components.day!,
                "hour": components.hour!,
                "minute": components.minute!,
                "longitude": longitude,
                "latitude": latitude,
                "city": city,
                "timezone": "America/Anchorage",
                "zodiac_type": "Tropic"
            ]] as [String : Any]

            guard let postData = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
                print("Failed to serialize data")
                return
            }

            let request = NSMutableURLRequest(
                url: NSURL(string: "https://astrologer.p.rapidapi.com/api/v4/birth-chart")! as URL,
                cachePolicy: .useProtocolCachePolicy,
                timeoutInterval: 10.0
            )
            request.httpMethod = "POST"
            request.allHTTPHeaderFields = headers
            request.httpBody = postData as Data

            let session = URLSession.shared
            let dataTask = session.dataTask(with: request as URLRequest) { (data, response, error) in
                if let error = error {
                    print("Error making API call: \(error.localizedDescription)")
                    return
                } else if let data = data {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                        print("Raw JSON response: \(json ?? [:])")

                        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                            if let planetData = json?["data"] as? [String: Any] {
                                var fetchedPlanets = [PlanetInfo]()

                                for (key, value) in planetData {
                                    if key != "utc_time" && key != "local_time" && key != "julian_day" && key != "name" && key != "month" && key != "hour" && key != "year" && key != "day" && key != "minute" && key != "lng" && key != "lat" && key != "tz_str" && key != "city" && key != "nation" && key != "zodiac_type" {
                                        if let planetDict = value as? [String: Any] {
                                            if let planet = try? PlanetInfo(dictionary: planetDict) {
                                                fetchedPlanets.append(planet)
                                            }
                                        }
                                    }
                                }

                                DispatchQueue.main.async {
                                    self.planets = fetchedPlanets

                                    if let encodedData = try? JSONEncoder().encode(fetchedPlanets) {
                                        UserDefaults.standard.set(encodedData, forKey: "userPlanetInfo")
                                        print("Planet information saved successfully.")
                                    }
                                }
                            } else {
                                print("Error: Planet data not found in JSON response")
                            }
                        } else {
                            print("Received non-200 HTTP response.")
                        }
                    } catch {
                        print("Failed to decode JSON: \(error)")
                    }
                }
            }
            dataTask.resume()
        }
    }

    private func fullSignName(from abbreviation: String) -> String {
        let signs = [
            "ari": "Aries",
            "tau": "Taurus",
            "gem": "Gemini",
            "can": "Cancer",
            "leo": "Leo",
            "vir": "Virgo",
            "lib": "Libra",
            "sco": "Scorpio",
            "sag": "Sagittarius",
            "cap": "Capricorn",
            "aqu": "Aquarius",
            "pis": "Pisces"
        ]
        return signs[abbreviation.lowercased()] ?? abbreviation
    }

    private func fullHouseName(from abbreviation: String) -> String {
        return abbreviation
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
}

struct PlanetInfo: Codable, Identifiable {
    var id: String { name }
    let name: String
    let quality: String
    let element: String
    let sign: String
    let signNum: Int
    let position: Double
    let absPos: Double
    let emoji: String
    let pointType: String
    let house: String
    let retrograde: Bool
}

extension PlanetInfo {
    init?(dictionary: [String: Any]) {
        guard let name = dictionary["name"] as? String,
              let quality = dictionary["quality"] as? String,
              let element = dictionary["element"] as? String,
              let sign = dictionary["sign"] as? String,
              let signNum = dictionary["sign_num"] as? Int,
              let position = dictionary["position"] as? Double,
              let absPos = dictionary["abs_pos"] as? Double,
              let emoji = dictionary["emoji"] as? String,
              let pointType = dictionary["point_type"] as? String,
              let house = dictionary["house"] as? String,
              let retrograde = dictionary["retrograde"] as? Bool else {
            return nil
        }

        self.name = name
        self.quality = quality
        self.element = element
        self.sign = sign
        self.signNum = signNum
        self.position = position
        self.absPos = absPos
        self.emoji = emoji
        self.pointType = pointType
        self.house = house
        self.retrograde = retrograde
    }
}

struct PlanetDetailView: View {
    let planet: PlanetInfo
    
    var body: some View {
        Text("Hello, this is the detail view for \(planet.name)")
            .font(.largeTitle)
            .padding()
            .navigationTitle(planet.name)
    }
}

struct CompatibilityOptionView: View {
    var body: some View {
            VStack {
                Text("Choose Compatibility Type")
                    .font(.largeTitle)
                    .padding()

                NavigationLink(destination: CompatibilityInputView(compatibilityType: "friendship")) {
                    Text("Friendship Compatibility")
                        .font(.title)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()

                NavigationLink(destination: CompatibilityInputView(compatibilityType: "partner")) {
                    Text("Partner Compatibility")
                        .font(.title)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
        }
    }
struct CompatibilityInputView: View {
    var compatibilityType: String
    @State private var partnerName: String = ""
    @State private var partnerBirthday: Date = Date()
    @Environment(\.presentationMode) var presentationMode
    

    var body: some View {
            Form {
                Section(header: Text("Enter \(compatibilityType.capitalized) Details")) {
                    TextField("\(compatibilityType.capitalized) Name", text: $partnerName)
                    DatePicker("\(compatibilityType.capitalized) Birthday", selection: $partnerBirthday, displayedComponents: [.date])
                }

                NavigationLink(destination: CompatibilityResultView(
                    compatibilityType: compatibilityType,
                    partnerName: partnerName,
                    partnerBirthday: partnerBirthday
                )) {
                    Text("Get Compatibility Summary")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding()
            }
            .navigationBarTitle("\(compatibilityType.capitalized) Compatibility", displayMode: .inline)
        }
    }

struct CompatibilityResultView: View {
    var compatibilityType: String
    var partnerName: String
    var partnerBirthday: Date
    @State private var compatibilityResult: CompatibilityResult?
    private let sampleMessage = """
        Provide an analysis of Teddy (born on Apr 21, 2003) and Blake (born on october 21st, 2003)'s relationship compatibility. List strengths, weaknesses, and tips for success.
        """
    private let sampleResponse = """
            {
              "Strengths": {
                "Aspects": [
                  {
                    "Compatibility": "Solid",
                    "Description": "As both Teddy (Taurus) and Blake (Libra) are ruled by Venus, the planet of love and beauty, they share a love for aesthetics, comfort, and harmony. This mutual appreciation can create a strong bond."
                  },
                  {
                    "Communication": "Effective",
                    "Description": "Libra's sociability and charm combined with Taurus’s sincerity can lead to effective and meaningful communication. They often understand each other's needs and desires."
                  },
                  {
                    "Balance": "Complementary",
                    "Description": "Libra's intellectual and social strengths complement Taurus's grounded and practical nature. This can lead to a balanced relationship where each fills in the gaps for the other."
                  }
                ]
              },
              "Weaknesses": {
                "Aspects": [
                  {
                    "Decision-Making": "Challenging",
                    "Description": "Taurus can be stubborn while Libra is indecisive, making it difficult for them to make decisions together. This can lead to frustration and conflict."
                  },
                  {
                    "Social Preferences": "Clashing",
                    "Description": "Libra enjoys socializing and engaging in social activities, whereas Taurus may prefer a more quiet and home-centered life. This difference can cause tension."
                  },
                  {
                    "Conflict Resolution": "Imbalance",
                    "Description": "Libra tends to avoid conflict and seeks harmony, while Taurus can be unyielding and persistent during disagreements, potentially leading to unresolved issues."
                  }
                ]
              },
              "Tips": [
                {
                  "Tip": "Enhance Communication",
                  "Description": "Open and honest communication is key. Regularly discuss any issues or concerns to prevent misunderstandings from festering."
                },
                {
                  "Tip": "Find Common Ground",
                  "Description": "Engage in activities that both enjoy to strengthen the bond. This could be anything from artistic endeavors to enjoying nature."
                },
                {
                  "Tip": "Compromise",
                  "Description": "Both should learn to compromise, balancing Taurus's persistence with Libra's need for harmony. This can help in decision-making and conflict resolution."
                }
              ]
            }
            """

    var body: some View {
            VStack {
                if let result = compatibilityResult {
                    ScrollView {
                                VStack(alignment: .leading, spacing: 20) {
                                    SectionHeader(title: "Strengths")
                                    ForEach(result.strengths.aspects, id: \.title) { aspect in
                                        AspectView(aspect: aspect)
                                    }

                                    SectionHeader(title: "Weaknesses")
                                    ForEach(result.weaknesses.aspects, id: \.title) { aspect in
                                        AspectView(aspect: aspect)
                                    }

                                    SectionHeader(title: "Tips")
                                    ForEach(result.tips, id: \.tip) { tip in
                                        TipView(tip: tip)
                                    }
                                }
                                .padding()
                            }
                } else {
                    ProgressView("Calculating Compatibility...")
                        .onAppear {
                            getCompatibilitySummary()
                        }
                }
            }
            .navigationTitle("Compatibility Summary")
        }

    func getCompatibilitySummary() {
            let userName = UserDefaults.standard.string(forKey: "userName") ?? "N/A"
            let userBirthday = UserDefaults.standard.object(forKey: "userBirthday") as? Date ?? Date()

            let userBirthdayString = DateFormatter.localizedString(from: userBirthday, dateStyle: .medium, timeStyle: .none)
            let partnerBirthdayString = DateFormatter.localizedString(from: partnerBirthday, dateStyle: .medium, timeStyle: .none)

            let prompt = """
            Provide an analysis of \(userName) (born on \(userBirthdayString)) and \(partnerName) (born on \(partnerBirthdayString))'s \(compatibilityType) compatibility. List strengths, weaknesses, and tips for success. Produce your output as a json, with "Strengths", "Weaknesses", and "Tips" as keys.
            """

            // Make an API call to OpenAI's GPT-4.0 with the prompt
            // Update `compatibilityResult` with the response

            let apiURL = URL(string: "https://api.openai.com/v1/chat/completions")!
            var request = URLRequest(url: apiURL)
            request.httpMethod = "POST"
            request.addValue("Bearer removed apiKey for security purposes", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")

            let requestBody: [String: Any] = [
                    "model": "gpt-4o",
                    "response_format" : ["type": "json_object"],
                    "messages": [
                        ["role": "system", "content": "You are a helpful and spiritual astrological assistant. Produce your output as a json exactly like the following format."],
                        ["role": "user", "content": sampleMessage],
                        ["role": "assistant", "content": sampleResponse],
                        ["role": "user", "content": prompt]
                    ],
                    "max_tokens": 500
                ]
            print(requestBody)

            guard let httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: []) else {
                print("Error: Unable to encode parameters as JSON")
                return
            }

            request.httpBody = httpBody

            URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        print("HTTP Error: \(error.localizedDescription)")
                        return
                    }

                    guard let data = data else {
                        print("Error: No data received")
                        return
                    }

                    // Print the raw JSON response
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("Raw JSON response: \(jsonString)")
                    }

                    do {
                        if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                           let choices = jsonResponse["choices"] as? [[String: Any]],
                           let message = choices.first?["message"] as? [String: Any],
                           let text = message["content"] as? String,
                           let responseData = text.data(using: .utf8){
                            let compatibilityRes = try JSONDecoder().decode(CompatibilityResult.self, from: responseData)
                            DispatchQueue.main.async {
                                print(text)
                                print(compatibilityRes)
                                self.compatibilityResult = compatibilityRes
                            }
                        } else {
                            print("Error: Invalid JSON response structure")
                        }
                    } catch {
                        print("Error parsing JSON: \(error.localizedDescription)")
                    }
                }.resume()
            }
}



struct CompatibilityResult: Codable {
    struct StrengthsWeaknesses: Codable {
        struct Aspect: Codable {
            let title: String
            let description: String
            
            enum CodingKeys: String, CodingKey {
                case description = "Description"
            }
            
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
                
                // Identify the dynamic key
                if let dynamicKey = container.allKeys.first(where: { $0.stringValue != "Description" }) {
                    title = dynamicKey.stringValue
                    description = try container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "Description")!)
                } else {
                    title = "Unknown"
                    description = ""
                }
            }
        }

        let aspects: [Aspect]

        enum CodingKeys: String, CodingKey {
            case aspects = "Aspects"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            var aspectsArray: [Aspect] = []

            // Decode the nested container with dynamic keys
            var aspectsContainer = try container.nestedUnkeyedContainer(forKey: .aspects)
            while !aspectsContainer.isAtEnd {
                let aspect = try aspectsContainer.decode(Aspect.self)
                aspectsArray.append(aspect)
            }

            self.aspects = aspectsArray
        }
    }
    
    struct Tip: Codable {
        let tip: String
        let description: String

        enum CodingKeys: String, CodingKey {
            case tip = "Tip"
            case description = "Description"
        }
    }

    let strengths: StrengthsWeaknesses
    let weaknesses: StrengthsWeaknesses
    let tips: [Tip]

    enum CodingKeys: String, CodingKey {
        case strengths = "Strengths"
        case weaknesses = "Weaknesses"
        case tips = "Tips"
    }
}

struct DynamicCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        return nil
    }
}

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(.primary)
            .padding(.top, 20)
    }
}

struct AspectView: View {
    let aspect: CompatibilityResult.StrengthsWeaknesses.Aspect

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(aspect.title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            Text(aspect.description)
                .font(.body)
                .foregroundColor(.primary)
        }
    }
}

struct TipView: View {
    let tip: CompatibilityResult.Tip

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(tip.tip)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            Text(tip.description)
                .font(.body)
                .foregroundColor(.primary)
        }
    }
}
