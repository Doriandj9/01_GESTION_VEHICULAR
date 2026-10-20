import { Injectable } from "@angular/core";
import { BehaviorSubject } from "rxjs";

@Injectable({ providedIn: 'root' })
export class LoaderService {
    private _status = new BehaviorSubject<boolean>(false);
    public status$ = this._status.asObservable();

    display(value: boolean): void { this._status.next(value); }
}