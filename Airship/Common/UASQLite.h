/*
 Copyright 2009-2014 Urban Airship Inc. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.

 2. Redistributions in binaryform must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided withthe distribution.

 THIS SOFTWARE IS PROVIDED BY THE URBAN AIRSHIP INC``AS IS'' AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 EVENT SHALL URBAN AIRSHIP INC OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>

#import "sqlite3.h"

@interface UASQLite : NSObject {
    sqlite3 *_db;
}

@property (atomic, assign) NSInteger busyRetryTimeout;
@property (nonatomic, copy) NSString *dbPath;

- (instancetype)initWithDBPath:(NSString *)aDBPath;

- (BOOL)open:(NSString *)aDBPath;
- (void)close;

/*error info*/
- (NSString*)lastErrorMessage;
- (NSInteger)lastErrorCode;

/*query, select data*/
- (NSArray *)executeQuery:(NSString *)sql, ...;
- (NSArray *)executeQuery:(NSString *)sql arguments:(NSArray *)args;

/*update methods, update/insert/delete data*/
- (BOOL)executeUpdate:(NSString *)sql, ...;
- (BOOL)executeUpdate:(NSString *)sql arguments:(NSArray *)args;

/*transaction*/
- (BOOL)commit;
- (BOOL)rollback;
- (BOOL)beginTransaction;
- (BOOL)beginDeferredTransaction;

/*helper methods*/
- (BOOL)tableExists:(NSString*)tableName;
- (BOOL)indexExists:(NSString*)indexName;

@end
