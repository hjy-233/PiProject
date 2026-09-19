import Hummingbird

struct APIError: Error, HTTPResponseError, Sendable {
    let status: HTTPResponse.Status
    let code: String
    let message: String

    func response(
        from request: Request,
        context: some RequestContext,
    ) throws -> Response {
        let body = APIErrorEnvelope(
            error: .init(code: code, message: message),
        )
        var response = try context.responseEncoder.encode(
            body,
            from: request,
            context: context,
        )
        response.status = status
        return response
    }
}

struct APIErrorEnvelope: Codable, Equatable, Sendable {
    struct Details: Codable, Equatable, Sendable {
        let code: String
        let message: String
    }

    let error: Details
}

struct APIErrorMiddleware<Context: RequestContext>: RouterMiddleware {
    func handle(
        _ request: Request,
        context: Context,
        next: (Request, Context) async throws -> Response,
    ) async throws -> Response {
        do {
            return try await next(request, context)
        } catch let error as APIError {
            throw error
        } catch let error as any HTTPResponseError {
            throw APIError(
                status: error.status,
                code: Self.code(for: error.status),
                message: Self.message(for: error.status),
            )
        } catch {
            context.logger.error(
                "Unhandled request error",
                metadata: ["errorType": "\(String(reflecting: type(of: error)))"],
            )
            throw APIError(
                status: .internalServerError,
                code: "internal_error",
                message: "The request could not be completed.",
            )
        }
    }

    private static func code(for status: HTTPResponse.Status) -> String {
        switch status {
        case .badRequest:
            "invalid_request"
        case .unauthorized:
            "unauthorized"
        case .forbidden:
            "forbidden"
        case .notFound:
            "not_found"
        case .conflict:
            "conflict"
        case .contentTooLarge:
            "payload_too_large"
        case .unprocessableContent:
            "validation_failed"
        default:
            status.code >= 500 ? "internal_error" : "request_failed"
        }
    }

    private static func message(for status: HTTPResponse.Status) -> String {
        switch status {
        case .badRequest:
            "The request is invalid."
        case .unauthorized:
            "Authentication is required."
        case .forbidden:
            "The requested operation is not allowed."
        case .notFound:
            "The requested resource was not found."
        case .conflict:
            "The request conflicts with the current state."
        case .contentTooLarge:
            "The request body is too large."
        case .unprocessableContent:
            "The request failed validation."
        default:
            "The request could not be completed."
        }
    }
}
