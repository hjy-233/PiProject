import Hummingbird

struct APIError: Error, HTTPResponseError, Sendable {
    let status: HTTPResponse.Status
    let code: String
    let message: String

    func response(from request: Request, context: some RequestContext) throws -> Response {
        var response = try context.responseEncoder.encode(
            APIErrorEnvelope(error: .init(code: code, message: message)),
            from: request,
            context: context,
        )
        response.status = status
        return response
    }
}

struct APIErrorEnvelope: Codable, Sendable {
    struct Details: Codable, Sendable {
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
            throw APIError(status: error.status, code: "request_failed", message: "The request could not be completed.")
        } catch {
            context.logger.error(
                "Unhandled request error",
                metadata: ["type": "\(String(reflecting: type(of: error)))"],
            )
            throw APIError(
                status: .internalServerError,
                code: "internal_error",
                message: "The request could not be completed.",
            )
        }
    }
}
