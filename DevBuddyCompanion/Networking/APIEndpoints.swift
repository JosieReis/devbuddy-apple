import Foundation

enum APIEndpoint {
    case upcomingEvents(minutesAhead: Int)
    case preferences
    case updatePreferences

    static let baseURL: URL = {
        if let urlString = ProcessInfo.processInfo.environment["DEVBUDDY_API_URL"],
           let url = URL(string: urlString) {
            return url
        }
        return URL(string: "http://localhost:3001")!
    }()

    var path: String {
        switch self {
        case .upcomingEvents:
            return "/calendar/events"
        case .preferences, .updatePreferences:
            return "/notifications/preferences"
        }
    }

    var method: String {
        switch self {
        case .upcomingEvents, .preferences:
            return "GET"
        case .updatePreferences:
            return "PATCH"
        }
    }

    func url(baseURL: URL) -> URL? {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)

        switch self {
        case .upcomingEvents(let minutesAhead):
            let now = Date()
            let end = now.addingTimeInterval(TimeInterval(minutesAhead * 60))
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            components?.queryItems = [
                URLQueryItem(name: "start", value: formatter.string(from: now)),
                URLQueryItem(name: "end", value: formatter.string(from: end))
            ]
        default:
            break
        }

        return components?.url
    }
}
