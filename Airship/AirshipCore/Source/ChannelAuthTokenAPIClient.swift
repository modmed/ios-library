/* Copyright Airship and Contributors */

final class ChannelAuthTokenAPIClient: ChannelAuthTokenAPIClientProtocol, Sendable {
    private let tokenPath = "/api/auth/device"
    private let config: RuntimeConfig
    private let session: AirshipRequestSession
    private let decoder: JSONDecoder = JSONDecoder()
    private let date: AirshipDateProtocol

    init(
        config: RuntimeConfig,
        session: AirshipRequestSession,
        date: AirshipDateProtocol = AirshipDate.shared
    ) {
        self.config = config
        self.session = session
        self.date = date
    }

    convenience init(config: RuntimeConfig) {
        self.init(
            config: config,
            session: config.requestSession
        )
    }

    private func makeURL(path: String) throws -> URL {
        guard let deviceAPIURL = self.config.deviceAPIURL else {
            throw AirshipErrors.error("Initial config not resolved.")
        }

        let urlString = "\(deviceAPIURL)\(path)"

        guard let url = URL(string: "\(deviceAPIURL)\(path)") else {
            throw AirshipErrors.error("Invalid ChannelAPIClient URL: \(String(describing: urlString))")
        }

        return url
    }


    ///
    /// Retrieves the token associated with the provided channel ID.
    /// - Parameters:
    ///   - channelID: The channel ID.
    /// - Returns: AuthToken if succeed otherwise it throws an error
    func fetchToken(
        channelID: String
    ) async throws -> AirshipHTTPResponse<ChannelAuthTokenResponse> {
        let nonce = UUID().uuidString
        let timestamp = AirshipUtils.ISODateFormatterUTC().string(from: date.now)

        let url = try makeURL(path: self.tokenPath)
        let token = try AirshipUtils.generateSignedToken(
            secret: config.appSecret,
            tokenParams: [
                config.appKey,
                channelID,
                nonce,
                timestamp
            ]
        )

        let request = AirshipRequest(
            url: url,
            headers: [
                "Accept": "application/vnd.urbanairship+json; version=3;",
                "X-UA-Channel-ID": channelID,
                "X-UA-Appkey": self.config.appKey,
                "X-UA-Nonce": nonce,
                "X-UA-Timestamp": timestamp
            ],
            method: "GET",
            auth: .bearer(token: token)
        )


        return try await session.performHTTPRequest(
            request
        ) { data, response in

            AirshipLogger.trace("Channel auth token request finished with status: \(response.statusCode)");

            guard response.statusCode == 200 else {
                return nil
            }

            let responseBody: ChannelAuthTokenResponse = try JSONUtils.decode(data: data)
            return responseBody
        }
    }
}

struct ChannelAuthTokenResponse: Decodable, Sendable {
    let token: String
    let expiresInMillseconds: UInt

    enum CodingKeys: String, CodingKey {
        case token = "token"
        case expiresInMillseconds = "expires_in"
    }
}

/// - Note: For internal use only. :nodoc:
protocol ChannelAuthTokenAPIClientProtocol: Sendable {
    func fetchToken(
        channelID: String
    ) async throws -> AirshipHTTPResponse<ChannelAuthTokenResponse>
}
