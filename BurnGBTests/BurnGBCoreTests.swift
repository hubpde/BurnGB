//
//  BurnGBCoreTests.swift
//  BurnGBTests
//
//  核心模型、格式化和配额账本单元测试。
//

import XCTest
@testable import BurnGBCore

final class BurnGBCoreTests: XCTestCase {
    func testByteFormattingUsesBinaryByteUnits() {
        XCTAssertEqual(ByteFormatting.bytes(1024).text, "1 KB")
        XCTAssertEqual(ByteFormatting.bytes(1024 * 1024).text, "1.0 MB")
    }

    func testBitrateUsesDecimalBitUnits() {
        let result = ByteFormatting.bitsPerSecond(125_000)
        XCTAssertEqual(result.unit, "Mbps")
        XCTAssertEqual(result.value, "1.0")
    }

    func testQuotaLedgerClampsConcurrentChunks() async {
        let ledger = QuotaLedger(quotaBytes: 100)
        async let first = ledger.ingest(75)
        async let second = ledger.ingest(75)
        let decisions = await [first, second]

        XCTAssertEqual(decisions.map(\.acceptedBytes).reduce(0, +), 100)
        let totals = await ledger.totals()
        XCTAssertEqual(totals.accepted, 100)
        XCTAssertTrue(totals.reachedQuota)
    }

    func testNodeRejectsNonHTTPSAndCredentials() {
        let http = BurnNode(name: "HTTP", urlString: "http://example.com/file", group: "test")
        let credentials = BurnNode(name: "Credentials", urlString: "https://user:pass@example.com/file", group: "test")
        let https = BurnNode(name: "HTTPS", urlString: "https://example.com/file", group: "test")

        XCTAssertNil(http.url)
        XCTAssertNil(credentials.url)
        XCTAssertNotNil(https.url)
    }

    func testRunIDIsCodable() throws {
        let runID = RunID()
        let data = try JSONEncoder().encode(runID)
        let decoded = try JSONDecoder().decode(RunID.self, from: data)
        XCTAssertEqual(decoded, runID)
    }
}
