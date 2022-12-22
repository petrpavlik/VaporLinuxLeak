import Fluent
import FluentPostgresDriver
import Vapor
import Queues

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.databases.use(.postgres(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? PostgresConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
        password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
        database: Environment.get("DATABASE_NAME") ?? "vapor_database",
        tlsConfiguration: .forClient(certificateVerification: .none)
    ), as: .psql)

    app.migrations.add(CreateTodo())
    try app.autoMigrate().wait()

    // register routes
    try routes(app)
    
    try app.queues.use(.memory())
    
    app.queues
        .schedule(CreateTodosScheduledJob())
        .hourly().at(0)
    
    app.queues
        .schedule(QueryTodosScheduledJob())
        .hourly().at(30)
}

struct CreateTodosScheduledJob: AsyncScheduledJob {
    func run(context: QueueContext) async throws {
        for i in 0..<1000 {
            let todo = Todo(title: "\(i)")
            try await todo.save(on: context.application.db)
            try await Task.sleep(nanoseconds: 1_000_000_000)
        }
    }
}

struct QueryTodosScheduledJob: AsyncScheduledJob {
    func run(context: QueueContext) async throws {
        for i in 0..<1000 {
            _ = try await Todo.query(on: context.application.db).all()
            try await Task.sleep(nanoseconds: 1_000_000_000)
        }
    }
}
