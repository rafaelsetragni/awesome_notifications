"""Reads `dumpsys notification --noredact` on stdin and prints, for one
package, what each of its notifications shows: stable lines only (no object
addresses, uids, package names or absolute times), sorted by id, so two apps
posting the same notifications diff cleanly. Used by render_diff.sh."""
import re
import sys

PACKAGE = sys.argv[1]

# Lines that change on every run or between apps, not with the notification.
VOLATILE = (
    'uid=', 'opPkg=', 'seen=', 'stats=', 'mContactAffinity', 'mPackagePriority',
    'mPackageVisibility', 'mRankingTimeMs', 'mCreationTimeMs', 'mVisibleSinceMs',
    'mUpdateTimeMs', 'mInterruptionTimeMs', 'mGlobalSortKey', 'mImportanceExplanation',
    'mProposedImportance', 'mIsAppImportanceLocked', 'mSensitiveContent',
    'mCanceledAfterLifetimeExtension', 'mIntercept', 'mHidden', 'mSystemImportance',
    'mAsstImportance', 'android.appInfo', 'android.reduced.images', 'mAdjustments',
    'mShortcutInfo', 'mUserSentiment', 'mSuppressedVisualEffects', 'mPeopleOverride',
    'mTextChanged', 'mRecordedInterruption', 'mInterruptive', 'mAllowBubble',
    'mIsNotConversationOverride', 'mHasSeenSmartReplies', 'mFlagBubbleRemoved',
    'mPostSilently', 'mPendingLogUpdate', 'mEditChoicesBeforeSending', 'mStats',
    'mTrimCache', 'mSystemGeneratedSmartActions', 'mSmartReplies', 'mRankingScore',
    'mProposedImportance', 'mImportanceFixed', 'mCriticality', 'key=',
)


def normalize(line, created):
    line = line.replace(PACKAGE, 'PKG')
    line = re.sub(r'\b\d{4,5}\|PKG', 'USER|PKG', line)
    line = re.sub(r'\|PKG\|(-?\d+)\|([^|]*)\|\d+', r'|PKG|\1|\2|UID', line)
    line = re.sub(r'(0x[0-9a-f]{5,}|\b[0-9a-f]{7,8}\b)(?=[:\s}])', 'ADDR', line)
    line = re.sub(r'(Icon\(typ=RESOURCE) pkg=\S+ id=0x[0-9a-f]+', r'\1', line)
    line = re.sub(r'(typ=BITMAP) size=\d+x\d+', r'\1', line)
    line = re.sub(r'PendingIntent\{[^}]*\}+', 'PendingIntent', line)
    line = re.sub(r'android\.(largeIcon|picture|largeIcon\.big)=Icon \(.*\)',
                  lambda m: 'android.%s=Icon (%s)' % (m.group(1), 'BITMAP' if 'BITMAP' in m.group(0) else m.group(0)), line)

    def when(m):  # absolute times → seconds from the notification's creation
        return '%s=%+ds' % (m.group(1), round((int(m.group(2)) - created) / 1000))
    if created:
        line = re.sub(r'\b(when|android\.chronometerBase)=(\d{12,})', when, line)
        line = re.sub(r'when=([+-]\d+s)/\d{12,}', r'when=\1', line)
    line = re.sub(r', mLastNotificationUpdateTimeMs=\d+', '', line)
    # 0.12 sortKey = (Long.MAX_VALUE - post time) followed by the id.
    line = re.sub(r'sortKey=\d{19}(\d+)', r'sortKey=<MAX-time>\1', line)
    line = re.sub(r'\|\d{5}\|', '|UID|', line)
    return line.rstrip()


def main():
    text = sys.stdin.read()
    chunks = re.split(r'\n(?=\s*NotificationRecord\()', text)
    records = {}
    for chunk in chunks:
        head = chunk.lstrip().split('\n', 1)[0]
        if not head.startswith('NotificationRecord(') or ('pkg=%s ' % PACKAGE) not in head:
            continue
        m = re.search(r' id=(-?\d+) ', head)
        if not m:
            continue
        nid = int(m.group(1))
        body = chunk.split('\n')
        created = 0
        for line in body:
            c = re.search(r'mCreationTimeMs=(\d+)', line)
            if c:
                created = int(c.group(1))
        out = []
        in_extras = False
        for line in body[1:]:
            if line.strip().startswith('NotificationRecord('):
                continue
            stripped = line.strip()
            if stripped == '' or any(stripped.startswith(v) for v in VOLATILE):
                continue
            # Inside extras={…}: only Android's own keys (0.12 also stores its
            # private keys there, which no app sees); a null extra draws nothing.
            if in_extras and stripped != '}' and (
                    not stripped.startswith('android.') or stripped.endswith('=null')):
                continue
            if stripped.startswith('extras={'):
                in_extras = True
            elif stripped == '}':
                in_extras = False
            out.append(normalize(line, created))
        lines = [normalize(head, created).strip()] + out
        name = '%d' % nid
        # A group summary's id is random in 0.12: name it by its group.
        g = re.search(r'groupKey=(\S+) ', head)
        if 'GROUP_SUMMARY' in head and 'AUTOGROUP' not in head and g:
            name = 'summary of %s' % g.group(1)
            lines = [l.replace(str(nid), '<summaryId>') for l in lines]
        if len(lines) > len(records.get(name, [])):
            records[name] = lines
    for name in sorted(records, key=lambda n: (not n[0].isdigit(), n.zfill(12))):
        print('## %s' % name)
        print('\n'.join(records[name]))
        print()


main()
