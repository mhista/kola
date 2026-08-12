// feature_availability_page.dart — '/feature-availability'.
//
// PHASE 10. The page that answers "why can't I see the feature I read
// about?" — a question that only exists because of the release-control
// system, and one that would otherwise become a support conversation
// every time a new capability is announced.
//
// Written for BUSINESS OWNERS, not API integrators — same audience as
// the Billing section's page, hence its own nav section rather than
// being folded into Reference. Deliberately explains the mechanism
// honestly rather than pretending unreleased features don't exist:
// people read changelogs and marketing pages, and being told "that's
// coming to your workspace soon" is far better than a feature they
// heard about simply not being there with no explanation.
//
// WHAT THIS PAGE DELIBERATELY DOES NOT DO: list which specific features
// are currently locked. That list changes with every release wave and
// would be stale within weeks, and the locked set is an unreleased
// roadmap we don't publish. The dashboard itself is the source of truth
// for what a given workspace can use.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../components/doc_page_kit.dart';

class FeatureAvailabilityPage extends StatelessComponent {
  const FeatureAvailabilityPage();

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      docH1('Why some features appear later'),
      docLede(
        'Kola is built in full and released in waves. A capability can be finished, running on '
        "our servers, and still not visible in your workspace yet — that's deliberate, and this "
        'page explains how it works and how to get access early.',
      ),

      docH2('The short version'),
      docP(
        'We build ahead of what we release. Shipping every capability the moment it works would '
        'hand a new business fifteen menu items on day one, most of which it has no use for yet. '
        'So features stay switched off until they are genuinely useful, and we turn them on in '
        'waves — each one building on the last.',
      ),
      docP(
        'Nothing is downloaded or installed when a feature arrives. It simply appears the next '
        'time you open your dashboard.',
      ),

      docH2('The four stages a feature moves through'),
      docList([
        'Building — written and tested, running on our servers, invisible to everyone. Most of '
            'what we have built at any moment is here.',
        'Internal — we use it ourselves, on our own workspaces, with real data. This is where we '
            'find out whether a feature is actually good rather than merely finished.',
        'Early access — a small number of businesses use it and tell us what is wrong. Usually '
            'fewer than five, always by agreement, never a surprise.',
        'Available — switched on for everyone whose plan includes it.',
      ]),

      docNote(
        'Early access is by invitation and agreement, not a percentage rollout. We would rather '
        'have five businesses we can call than five hundred we cannot.',
      ),

      docH2('How to get a feature early'),
      docP(
        'Ask. If a capability would genuinely help your business and you are willing to tell us '
        'when it gets something wrong, we will usually switch it on for your workspace '
        'specifically. That is exactly what early access is for.',
      ),
      docP(
        'Two honest caveats. Early-access features change without notice, and they are rougher '
        "than released ones — that is the trade. And a few capabilities we genuinely cannot "
        'switch on early no matter who asks, because they depend on approval from someone '
        'outside Kola.',
      ),

      docH2('Features we cannot unlock on request'),
      docP(
        'Some capabilities wait on a third party rather than on us:',
      ),
      docList([
        'Messenger and Instagram channels, and message broadcasts — these need approval from '
            'Meta for our platform. We cannot grant access ahead of that approval, and switching '
            'them on early would mean your messages being rejected.',
        'Single sign-on and data residency — these depend on security certification and legal '
            'agreements that take months of calendar time regardless of whether the software is '
            'ready.',
      ]),
      docWarning(
        'If someone offers to enable one of these for you ahead of approval, it will not work. '
        'The restriction is enforced by our systems specifically so that it cannot be bypassed '
        'by mistake.',
      ),

      docH2('Features that disappear'),
      docP(
        'Occasionally a feature you had access to stops being available. There are only two '
        'reasons this happens, and neither is silent:',
      ),
      docList([
        'We switched it off because it was misbehaving. We would rather remove something '
            'briefly than leave it giving you wrong answers. You will be told, and it comes back.',
        'Your plan changed. Some capabilities are on paid plans only. If a trial ended or a '
            'payment did not go through, the feature returns as soon as the plan does — nothing '
            'is deleted in the meantime.',
      ]),

      docH2('What your workspace can use right now'),
      docP(
        'Your dashboard is the authoritative answer. What you can see there is what you have. '
        'We deliberately do not publish a list of unreleased features here, because it would be '
        'out of date within weeks and would tell you about things you cannot use yet.',
      ),
      docNote(
        'If you read about something in a changelog or announcement and cannot find it in your '
        'dashboard, it is almost always waiting on a release wave rather than broken. Ask us and '
        'we will tell you where it is.',
      ),
    ]);
  }
}
