//
//  LocationController.m
//  Dolphin6
//
//  Created by Alexander Trofimov on 8/14/09.
//  Copyright 2009 BoonEx. All rights reserved.
//

#import "LocationController.h"

@implementation LocationController

CLLocationManager* locmanager = nil;

- (id)init {
	BxUser *u = [Dolphin6AppDelegate getCurrentUser];
	if ((self = [super initWithProfile:(u.strUsername) nav:nil])) {

    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	UIBarButtonItem *btn = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Current", @"Get current user location") style:UIBarButtonItemStyleDone target:self action:@selector(actionCurrentLocation:)];
	self.navigationItem.rightBarButtonItem = btn;
	[btn release];
}

- (void)dealloc {
	if (locmanager != nil) {
		[locmanager release];
		locmanager = nil;
	}
    [super dealloc];
}

/**********************************************************************************************************************
 ACTIONS
 **********************************************************************************************************************/

#pragma mark - Actions

/**
 * callback function on request info 
 */
- (void)actionUpdateUserLocation:(id)idData {	
	
	id resp = [[idData valueForKey:BX_KEY_RESP] retain];
	
	// if error occured 
	if([resp isKindOfClass:[NSError class]])
	{		
		[BxConnector showErrorAlertWithDelegate:self];
		return;
	}
	
	NSLog(@"user location update result: %@", resp);		
	[resp release];
}

- (IBAction)actionCurrentLocation:(id)sender {
	
	if (nil == locmanager) {
		locmanager = [[CLLocationManager alloc] init];
		[locmanager setDelegate:self];
		[locmanager setDesiredAccuracy:kCLLocationAccuracyBest];
	}
	[locmanager startUpdatingLocation];	
	[self addProgressIndicator];
}

/**********************************************************************************************************************
 DELEGATES: CLLocationManager
 **********************************************************************************************************************/

#pragma mark - CLLocationManager delegates

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
	
	[self removeProgressIndicator];
	
	[locmanager stopUpdatingLocation];
	
	CLLocationCoordinate2D coord = [newLocation coordinate];
	
	MKCoordinateRegion region;
	MKCoordinateSpan span;
	span.latitudeDelta = 0.005;
	span.longitudeDelta = 0.005;
	region.span = span;
	region.center = coord;
	[mapView regionThatFits:region];
	[mapView setRegion:region animated:YES];
	
	if (currAnnotation) {
		[mapView removeAnnotation:currAnnotation];
		[currAnnotation release];
		currAnnotation = nil;
	}
	
	currAnnotation = [[LocationAnnotation alloc] initWithLat:coord.latitude lng:coord.longitude];
	[mapView addAnnotation:currAnnotation];
	
	NSString *sMapType;
	switch (mapView.mapType) {
		case MKMapTypeHybrid:
			sMapType = @"hybrid";
			break;
		case MKMapTypeSatellite:
			sMapType = @"satellite";
			break;
		default:
			sMapType = @"standard";
			break;
	}
	
	NSArray *myArray = [NSArray arrayWithObjects:user.strUsername, user.strPwdHash, [NSString stringWithFormat:@"%.8f", coord.latitude], [NSString stringWithFormat:@"%.8f", coord.longitude], [NSString stringWithFormat:@"%d", [self deltaToZoom:span.latitudeDelta]], mapType, nil];
	[user.connector execAsyncMethod:@"dolphin.updateUserLocation" withParams:myArray withSelector:@selector(actionUpdateUserLocation:) andSelectorObject:self andSelectorData:nil useIndicator:nil];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
	[self removeProgressIndicator];
	
	[locmanager stopUpdatingLocation];
	
	UIAlertView *al = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Title", @"Error Alert Title") message:NSLocalizedString(@"Location update failed", @"Location update failed alert text") delegate:self cancelButtonTitle:NSLocalizedString(@"OK", @"OK Button Title") otherButtonTitles:nil];
	[al show];
	[al release];		
}

@end